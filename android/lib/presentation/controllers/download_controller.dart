import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile_app/core/constants/app_constants.dart';
import 'package:mobile_app/data/models/download_item.dart';
import 'package:mobile_app/data/models/video_metadata.dart';
import 'package:mobile_app/data/repositories/download_repository.dart';

enum DownloadFilter { all, active, completed }

class DownloadController extends ChangeNotifier {
  final DownloadRepository _repository;

  List<DownloadItem> _downloads = [];
  bool _isLoading = false;
  bool _isExtracting = false;
  String? _errorMessage;
  String? _technicalDetails;

  VideoMetadata? _currentMetadata;
  String _selectedFormat = AppConstants.formatMp4;
  String _selectedQuality = '720p';
  DownloadFilter _currentFilter = DownloadFilter.all;

  DownloadController({DownloadRepository? repository})
      : _repository = repository ?? DownloadRepository() {
    _init();
  }

  List<DownloadItem> get downloads {
    switch (_currentFilter) {
      case DownloadFilter.active:
        return _downloads.where((d) => d.isActive).toList();
      case DownloadFilter.completed:
        return _downloads.where((d) => d.isCompleted).toList();
      case DownloadFilter.all:
        return _downloads;
    }
  }

  bool get isLoading => _isLoading;
  bool get isExtracting => _isExtracting;
  String? get errorMessage => _errorMessage;
  String? get technicalDetails => _technicalDetails;
  VideoMetadata? get currentMetadata => _currentMetadata;
  String get selectedFormat => _selectedFormat;
  String get selectedQuality => _selectedQuality;
  DownloadFilter get currentFilter => _currentFilter;

  int get activeCount => _downloads.where((d) => d.isActive).length;
  int get completedCount => _downloads.where((d) => d.isCompleted).length;

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    await loadDownloads();
    _repository.subscribeToProgress(_onProgressUpdate);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDownloads() async {
    try {
      final items = await _repository.getAllDownloads();
      _downloads = List<DownloadItem>.from(items);
      notifyListeners();
    } catch (e, stack) {
      _errorMessage = 'Erro ao carregar lista de downloads: $e';
      _technicalDetails = stack.toString();
      notifyListeners();
    }
  }

  void setFilter(DownloadFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void setFormat(String format) {
    _selectedFormat = format;
    if (_currentMetadata != null) {
      if (format == AppConstants.formatMp3) {
        _selectedQuality = _currentMetadata!.audioFormats.isNotEmpty
            ? _currentMetadata!.audioFormats.first
            : 'mp3_320k';
      } else {
        _selectedQuality = _currentMetadata!.qualities.isNotEmpty
            ? _currentMetadata!.qualities.first
            : '720p';
      }
    }
    notifyListeners();
  }

  void setQuality(String quality) {
    _selectedQuality = quality;
    notifyListeners();
  }

  Future<void> extractMetadata(String url) async {
    if (url.trim().isEmpty) return;

    _isExtracting = true;
    _errorMessage = null;
    _technicalDetails = null;
    notifyListeners();

    try {
      final meta = await _repository.extractMetadata(url.trim());
      if (meta != null) {
        _currentMetadata = meta;
        if (meta.provider == 'Spotify' ||
            meta.provider == 'Deezer' ||
            meta.provider == 'YouTube Music') {
          _selectedFormat = AppConstants.formatMp3;
          _selectedQuality = meta.audioFormats.isNotEmpty
              ? meta.audioFormats.first
              : 'mp3_320k';
        } else {
          _selectedFormat = AppConstants.formatMp4;
          _selectedQuality = meta.qualities.isNotEmpty
              ? meta.qualities.first
              : '720p';
        }
      } else {
        _errorMessage = 'Não foi possível extrair os dados do link informado.';
      }
    } catch (e, stack) {
      _errorMessage = 'Erro ao processar o link: $e';
      _technicalDetails = stack.toString();
    } finally {
      _isExtracting = false;
      notifyListeners();
    }
  }

  void clearMetadata() {
    _currentMetadata = null;
    _errorMessage = null;
    _technicalDetails = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _technicalDetails = null;
    notifyListeners();
  }

  Future<void> startDownload() async {
    if (_currentMetadata == null) return;

    final meta = _currentMetadata!;
    _errorMessage = null;
    _technicalDetails = null;

    try {
      final newItem = await _repository.createDownload(
        url: meta.url,
        title: meta.title,
        provider: meta.provider,
        formatType: _selectedFormat,
        quality: _selectedQuality,
        thumbnailUrl: meta.thumbnail,
        directStreamUrl: meta.directStreamUrl,
      );

      final mutableList = List<DownloadItem>.from(_downloads);
      if (!mutableList.any((d) => d.downloadId == newItem.downloadId)) {
        mutableList.insert(0, newItem);
      }
      _downloads = mutableList;
      _currentMetadata = null;
      notifyListeners();
    } catch (e, stack) {
      _errorMessage = 'Falha ao iniciar download: $e';
      _technicalDetails = stack.toString();
      notifyListeners();
    }
  }

  Future<void> cancelDownload(String downloadId) async {
    try {
      await _repository.cancelDownload(downloadId);
      final index = _downloads.indexWhere((d) => d.downloadId == downloadId);
      if (index != -1) {
        _downloads[index] = _downloads[index].copyWith(
          status: AppConstants.statusCancelled,
        );
        notifyListeners();
      }
    } catch (e, stack) {
      _errorMessage = 'Erro ao cancelar download: $e';
      _technicalDetails = stack.toString();
      notifyListeners();
    }
  }

  Future<void> deleteDownload(String downloadId) async {
    try {
      await _repository.deleteDownload(downloadId, deleteFileFromDisk: true);
      _downloads.removeWhere((d) => d.downloadId == downloadId);
      notifyListeners();
    } catch (e, stack) {
      _errorMessage = 'Erro ao excluir download: $e';
      _technicalDetails = stack.toString();
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    try {
      await _repository.clearCompleted();
      _downloads.removeWhere((d) => !d.isActive);
      notifyListeners();
    } catch (e, stack) {
      _errorMessage = 'Erro ao limpar histórico: $e';
      _technicalDetails = stack.toString();
      notifyListeners();
    }
  }

  Future<void> openMedia(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await OpenFilex.open(filePath);
      } else {
        _errorMessage = 'Arquivo de mídia não encontrado no dispositivo.';
        notifyListeners();
      }
    } catch (e, stack) {
      _errorMessage = 'Erro ao abrir mídia: $e';
      _technicalDetails = stack.toString();
      notifyListeners();
    }
  }

  Future<void> shareMedia(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath)],
          ),
        );
      }
    } catch (e, stack) {
      _errorMessage = 'Erro ao compartilhar mídia: $e';
      _technicalDetails = stack.toString();
      notifyListeners();
    }
  }

  void _onProgressUpdate(DownloadItem updatedItem) {
    final mutableList = List<DownloadItem>.from(_downloads);
    final index = mutableList.indexWhere((d) => d.downloadId == updatedItem.downloadId);
    if (index != -1) {
      mutableList[index] = updatedItem;
    } else {
      mutableList.insert(0, updatedItem);
    }
    _downloads = mutableList;
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}

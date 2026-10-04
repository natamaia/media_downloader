import 'package:flutter/material.dart';
import 'package:mobile_app/core/constants/app_constants.dart';
import 'package:mobile_app/core/utils/error_handler.dart';
import 'package:mobile_app/presentation/controllers/download_controller.dart';
import 'package:mobile_app/presentation/widgets/download_item_card.dart';
import 'package:mobile_app/presentation/widgets/media_preview_card.dart';
import 'package:mobile_app/presentation/widgets/url_input_field.dart';

class HomeScreen extends StatefulWidget {
  final DownloadController controller;
  final VoidCallback onNavigateToDownloads;

  const HomeScreen({
    super.key,
    required this.controller,
    required this.onNavigateToDownloads,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final theme = Theme.of(context);
    final activeDownloads = controller.downloads.where((d) => d.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.download_for_offline_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'MediaDownloader',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sobre o Projeto',
            icon: const Icon(Icons.info_outline_rounded, size: 22),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.terminal_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      const Text('MediaDownloader Pro'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Downloader universal móvel de áudio e vídeo com motor Python embarcado.',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 18, color: Colors.blueAccent),
                          const SizedBox(width: 8),
                          Text(
                            'Autor: @${AppConstants.authorName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.code_rounded, size: 18, color: Colors.greenAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppConstants.repoUrl,
                              style: const TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Fechar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Input de URL
                UrlInputField(
                  controller: _urlController,
                  isExtracting: controller.isExtracting,
                  onExtract: () {
                    controller.extractMetadata(_urlController.text);
                  },
                  onClear: () {
                    controller.clearMetadata();
                  },
                ),
                const SizedBox(height: 16),

                // Card de Erro com Botão de Copiar
                if (controller.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1518),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.redAccent.withAlpha(120), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Erro Detectado',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SelectableText(
                                    controller.errorMessage!,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18, color: Colors.white70),
                              onPressed: () => controller.clearError(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (controller.technicalDetails != null)
                              TextButton.icon(
                                icon: const Icon(Icons.bug_report_outlined, size: 16, color: Colors.orangeAccent),
                                label: const Text('Ver Log Técnico', style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                                onPressed: () {
                                  ErrorHandler.showErrorDetailsDialog(
                                    context,
                                    title: 'Diagnóstico de Erro',
                                    errorMessage: controller.errorMessage!,
                                    technicalDetails: controller.technicalDetails,
                                  );
                                },
                              ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent.withAlpha(200),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: const Text('Copiar Erro', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                final textToCopy = StringBuffer()
                                  ..writeln('Erro: ${controller.errorMessage}')
                                  ..writeln('URL: ${_urlController.text}');
                                if (controller.technicalDetails != null) {
                                  textToCopy.writeln('Detalhes:\n${controller.technicalDetails}');
                                }
                                ErrorHandler.copyToClipboard(
                                  context,
                                  textToCopy.toString(),
                                  label: 'Mensagem de erro copiada para a área de transferência!',
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Card de Visualização do Vídeo Extraído
                if (controller.currentMetadata != null) ...[
                  MediaPreviewCard(
                    metadata: controller.currentMetadata!,
                    selectedFormat: controller.selectedFormat,
                    selectedQuality: controller.selectedQuality,
                    onFormatChanged: (fmt) => controller.setFormat(fmt),
                    onQualityChanged: (q) => controller.setQuality(q),
                    onStartDownload: () {
                      controller.startDownload();
                      _urlController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Download iniciado com sucesso!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    onDismiss: () => controller.clearMetadata(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Seção de Downloads Ativos
                if (activeDownloads.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Downloads em Andamento (${activeDownloads.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onNavigateToDownloads,
                        child: const Text('Ver Todos'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...activeDownloads.take(3).map(
                        (item) => DownloadItemCard(
                          item: item,
                          onCancel: () => controller.cancelDownload(item.downloadId),
                          onDelete: () => controller.deleteDownload(item.downloadId),
                          onOpen: () => controller.openMedia(item.filePath),
                          onShare: () => controller.shareMedia(item.filePath),
                        ),
                      ),
                ],

                // Banner Informativo de Suporte a Provedores
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor.withAlpha(120),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.verified_outlined,
                              size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Provedores Suportados',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'YouTube, YouTube Shorts (até 3 min), YouTube Music, Spotify, Deezer, TikTok, Instagram, Vimeo e centenas de outros sites.',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withAlpha(160),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // Marca d'água do Projeto e Repositório
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.code_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurface.withAlpha(140),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Desenvolvido por @${AppConstants.authorName}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withAlpha(180),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'github.com/${AppConstants.repoName}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary.withAlpha(210),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

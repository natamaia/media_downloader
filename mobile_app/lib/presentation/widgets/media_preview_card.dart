import 'package:flutter/material.dart';
import 'package:mobile_app/core/constants/app_constants.dart';
import 'package:mobile_app/core/utils/formatters.dart';
import 'package:mobile_app/data/models/video_metadata.dart';

class MediaPreviewCard extends StatelessWidget {
  final VideoMetadata metadata;
  final String selectedFormat;
  final String selectedQuality;
  final ValueChanged<String> onFormatChanged;
  final ValueChanged<String> onQualityChanged;
  final VoidCallback onStartDownload;
  final VoidCallback onDismiss;

  const MediaPreviewCard({
    super.key,
    required this.metadata,
    required this.selectedFormat,
    required this.selectedQuality,
    required this.onFormatChanged,
    required this.onQualityChanged,
    required this.onStartDownload,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMp3 = selectedFormat == AppConstants.formatMp3;
    final availableQualities = isMp3 ? metadata.audioFormats : metadata.qualities;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(80),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header com Título e Fechar
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        metadata.provider.toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      metadata.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Thumbnail com Badge de Duração
          if (metadata.thumbnail != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Image.network(
                    metadata.thumbnail!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      color: Colors.grey.withAlpha(50),
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 40),
                      ),
                    ),
                  ),
                  if (metadata.durationSeconds > 0)
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(200),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        Formatters.formatDuration(metadata.durationSeconds),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Seletor de Formato (Vídeo MP4 / Áudio MP3)
          Text(
            'Formato de Destino',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withAlpha(180),
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: AppConstants.formatMp4,
                icon: Icon(Icons.videocam_rounded),
                label: Text('Vídeo (MP4)'),
              ),
              ButtonSegment<String>(
                value: AppConstants.formatMp3,
                icon: Icon(Icons.audiotrack_rounded),
                label: Text('Áudio (MP3)'),
              ),
            ],
            selected: {selectedFormat},
            onSelectionChanged: (Set<String> newSelection) {
              onFormatChanged(newSelection.first);
            },
          ),
          const SizedBox(height: 16),

          // Seletor de Qualidade
          Text(
            'Qualidade',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withAlpha(180),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableQualities.map((qual) {
              final isSelected = qual == selectedQuality;
              return ChoiceChip(
                label: Text(qual),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) onQualityChanged(qual);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Botão Baixar Mídia
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onStartDownload,
              icon: const Icon(Icons.download_rounded, size: 24),
              label: const Text(
                'Baixar Mídia Agora',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

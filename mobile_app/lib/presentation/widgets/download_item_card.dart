import 'package:flutter/material.dart';
import 'package:mobile_app/core/constants/app_constants.dart';
import 'package:mobile_app/core/utils/error_handler.dart';
import 'package:mobile_app/core/utils/formatters.dart';
import 'package:mobile_app/data/models/download_item.dart';

class DownloadItemCard extends StatelessWidget {
  final DownloadItem item;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onOpen;
  final VoidCallback onShare;

  const DownloadItemCard({
    super.key,
    required this.item,
    required this.onCancel,
    required this.onDelete,
    required this.onOpen,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMp3 = item.formatType == AppConstants.formatMp3;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isActive
              ? theme.colorScheme.primary.withAlpha(80)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Ícone de formato, título e provider
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isMp3 ? Colors.amber : theme.colorScheme.primary)
                      .withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isMp3 ? Icons.audiotrack_rounded : Icons.videocam_rounded,
                  color: isMp3 ? Colors.amber : theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          item.provider,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withAlpha(160),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(40),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.quality.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(context),
            ],
          ),
          const SizedBox(height: 12),

          // Se estiver ativo: exibe barra de progresso, velocidade e ETA
          if (item.isActive) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: item.progressPercent > 0 ? (item.progressPercent / 100) : null,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surface,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.progressPercent.toStringAsFixed(1)}% • ${item.downloadSpeed}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withAlpha(200),
                  ),
                ),
                Text(
                  item.totalBytes > 0
                      ? '${Formatters.formatBytes(item.downloadedBytes)} / ${Formatters.formatBytes(item.totalBytes)}'
                      : 'Calculando tamanho...',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withAlpha(160),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tempo restante: ${Formatters.formatEta(item.etaSeconds)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withAlpha(140),
                  ),
                ),
                TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.redAccent),
                  label: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],

          // Se estiver completo ou existente: botões de ação (Abrir, Compartilhar, Excluir)
          if (item.isCompleted) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Compartilhar Mídia',
                  icon: const Icon(Icons.share_rounded, size: 20),
                  onPressed: onShare,
                ),
                IconButton(
                  tooltip: 'Excluir do Dispositivo',
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                  onPressed: onDelete,
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Abrir'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ],

          // Se falhou: exibe erro com botão de copiar
          if (item.isFailed && item.errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 18, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.errorMessage!,
                      style: const TextStyle(fontSize: 11, color: Colors.redAccent),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copiar Erro',
                    icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white70),
                    onPressed: () {
                      ErrorHandler.copyToClipboard(
                        context,
                        'Erro no download (${item.title}):\n${item.errorMessage}\nURL: ${item.url}',
                        label: 'Erro da tarefa copiado para a área de transferência!',
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Remover',
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color bg = Colors.grey.withAlpha(40);
    Color fg = Colors.grey;
    String label = item.status;

    if (item.status == AppConstants.statusDownloading) {
      bg = Theme.of(context).colorScheme.primary.withAlpha(40);
      fg = Theme.of(context).colorScheme.primary;
      label = 'Baixando';
    } else if (item.status == AppConstants.statusCompleted) {
      bg = Colors.green.withAlpha(40);
      fg = Colors.green;
      label = 'Concluído';
    } else if (item.status == AppConstants.statusExists) {
      bg = Colors.blue.withAlpha(40);
      fg = Colors.blue;
      label = 'No Disco';
    } else if (item.status == AppConstants.statusConverting) {
      bg = Colors.orange.withAlpha(40);
      fg = Colors.orange;
      label = 'Convertendo';
    } else if (item.status == AppConstants.statusFailed) {
      bg = Colors.red.withAlpha(40);
      fg = Colors.redAccent;
      label = 'Falha';
    } else if (item.status == AppConstants.statusCancelled) {
      bg = Colors.grey.withAlpha(40);
      fg = Colors.grey;
      label = 'Cancelado';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

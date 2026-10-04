import 'package:flutter/material.dart';
import 'package:mobile_app/presentation/controllers/download_controller.dart';
import 'package:mobile_app/presentation/widgets/download_item_card.dart';

class DownloadsScreen extends StatelessWidget {
  final DownloadController controller;

  const DownloadsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fila de Downloads',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Limpar Concluídos',
            icon: const Icon(Icons.playlist_remove_rounded),
            onPressed: () {
              controller.clearHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Downloads concluídos removidos da lista.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final items = controller.downloads;

          return Column(
            children: [
              // Barra de Filtros
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip(
                      context,
                      label: 'Todos',
                      filter: DownloadFilter.all,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context,
                      label: 'Ativos (${controller.activeCount})',
                      filter: DownloadFilter.active,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context,
                      label: 'Concluídos (${controller.completedCount})',
                      filter: DownloadFilter.completed,
                    ),
                  ],
                ),
              ),

              // Lista de Downloads
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_download_outlined,
                              size: 64,
                              color: theme.colorScheme.onSurface.withAlpha(80),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum download encontrado',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(160),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Cole um link na tela inicial para iniciar',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface.withAlpha(120),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => controller.loadDownloads(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return DownloadItemCard(
                              item: item,
                              onCancel: () => controller.cancelDownload(item.downloadId),
                              onDelete: () => controller.deleteDownload(item.downloadId),
                              onOpen: () => controller.openMedia(item.filePath),
                              onShare: () => controller.shareMedia(item.filePath),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required DownloadFilter filter,
  }) {
    final isSelected = controller.currentFilter == filter;
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: theme.colorScheme.primary.withAlpha(50),
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
      ),
      onSelected: (_) => controller.setFilter(filter),
    );
  }
}

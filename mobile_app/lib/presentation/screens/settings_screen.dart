import 'package:flutter/material.dart';
import 'package:mobile_app/core/constants/app_constants.dart';
import 'package:mobile_app/presentation/controllers/download_controller.dart';

class SettingsScreen extends StatelessWidget {
  final DownloadController controller;
  final bool isDarkMode;
  final ValueChanged<bool> onToggleTheme;

  const SettingsScreen({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configurações',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Seção Armazenamento
          _buildSectionHeader(context, 'Armazenamento & Arquivos'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.folder_outlined, color: theme.colorScheme.primary),
                  title: const Text('Pasta de Destino das Mídias'),
                  subtitle: const Text('Armazenamento do Dispositivo / MediaDownloader'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                  title: const Text('Limpar Histórico de Downloads'),
                  subtitle: const Text('Remove os registros concluídos da lista'),
                  onTap: () {
                    controller.clearHistory();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Histórico limpo com sucesso!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Seção Aparência
          _buildSectionHeader(context, 'Aparência & Interface'),
          Card(
            child: SwitchListTile(
              secondary: Icon(
                isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Tema Escuro'),
              subtitle: Text(isDarkMode ? 'Ativado' : 'Desativado'),
              value: isDarkMode,
              onChanged: onToggleTheme,
            ),
          ),
          const SizedBox(height: 24),

          // Seção Sobre
          _buildSectionHeader(context, 'Sobre a Aplicação'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  title: const Text(AppConstants.appName),
                  subtitle: const Text('Versão ${AppConstants.appVersion} Mobile APK'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.code_rounded, color: theme.colorScheme.primary),
                  title: const Text('Stack Tecnológica'),
                  subtitle: const Text('Flutter 3 + Motor Python (yt-dlp) Mobile'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.offline_pin_outlined, color: theme.colorScheme.primary),
                  title: const Text('Execução Autônoma'),
                  subtitle: const Text('Processamento 100% no dispositivo (sem servidores externos)'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.person_outline_rounded, color: theme.colorScheme.primary),
                  title: const Text('Desenvolvedor'),
                  subtitle: Text('@${AppConstants.authorName}'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.link_rounded, color: theme.colorScheme.primary),
                  title: const Text('Repositório Git'),
                  subtitle: Text('github.com/${AppConstants.repoName}'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: Column(
              children: [
                Text(
                  'MediaDownloader Mobile • @${AppConstants.authorName}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withAlpha(150),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.repoUrl,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

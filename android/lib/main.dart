import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/presentation/controllers/download_controller.dart';
import 'package:mobile_app/presentation/screens/downloads_screen.dart';
import 'package:mobile_app/presentation/screens/home_screen.dart';
import 'package:mobile_app/presentation/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configura a barra de status e navegação do sistema Android
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF121214),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MediaDownloaderApp());
}

class MediaDownloaderApp extends StatefulWidget {
  const MediaDownloaderApp({super.key});

  @override
  State<MediaDownloaderApp> createState() => _MediaDownloaderAppState();
}

class _MediaDownloaderAppState extends State<MediaDownloaderApp> {
  final DownloadController _downloadController = DownloadController();
  bool _isDarkMode = true;
  int _currentIndex = 0;

  @override
  void dispose() {
    _downloadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediaDownloader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(
              controller: _downloadController,
              onNavigateToDownloads: () {
                setState(() => _currentIndex = 1);
              },
            ),
            DownloadsScreen(controller: _downloadController),
            SettingsScreen(
              controller: _downloadController,
              isDarkMode: _isDarkMode,
              onToggleTheme: (val) {
                setState(() => _isDarkMode = val);
              },
            ),
          ],
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: _downloadController,
          builder: (context, _) {
            final activeCount = _downloadController.activeCount;

            return NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Início',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: activeCount > 0,
                    label: Text('$activeCount'),
                    child: const Icon(Icons.downloading_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: activeCount > 0,
                    label: Text('$activeCount'),
                    child: const Icon(Icons.downloading_rounded),
                  ),
                  label: 'Downloads',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: 'Configurações',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

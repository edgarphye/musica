import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/theme_controller.dart';
import 'close_app.dart';
import 'providers.dart';
import 'pages/about_page.dart';
import 'pages/browse_page.dart';
import 'pages/convert_page.dart';
import 'pages/recent_page.dart';
import 'widgets/player_bar.dart';

class MusicaApp extends ConsumerWidget {
  const MusicaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return MaterialApp(
      title: 'MusiConvert',
      debugShowCheckedModeBanner: false,
      theme: theme.build(),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _pages = [
    BrowsePage(),
    ConvertPage(),
    RecentPage(),
    AboutPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(
      playerControllerProvider.select((p) => p.state),
    );
    final showPlayer = playerState.currentTrack != null;

    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                if (wide)
                  NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: (i) => setState(() => _index = i),
                    labelType: NavigationRailLabelType.all,
                    trailing: Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: IconButton(
                            tooltip: 'Cerrar la aplicación',
                            onPressed: closeApplication,
                            icon: const Icon(Icons.power_settings_new),
                          ),
                        ),
                      ),
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.library_music_outlined),
                        selectedIcon: Icon(Icons.library_music),
                        label: Text('Explorar'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.swap_horiz_outlined),
                        selectedIcon: Icon(Icons.swap_horiz),
                        label: Text('Convertir'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.history_outlined),
                        selectedIcon: Icon(Icons.history),
                        label: Text('Recientes'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.info_outline),
                        selectedIcon: Icon(Icons.info),
                        label: Text('Acerca de'),
                      ),
                    ],
                  ),
                Expanded(
                  child: _pages[_index],
                ),
              ],
            ),
          ),
          if (showPlayer)
            SafeArea(
              top: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: const PlayerBar(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music),
                  label: 'Explorar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.swap_horiz_outlined),
                  selectedIcon: Icon(Icons.swap_horiz),
                  label: 'Convertir',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: 'Recientes',
                ),
                NavigationDestination(
                  icon: Icon(Icons.info_outline),
                  selectedIcon: Icon(Icons.info),
                  label: 'Acerca de',
                ),
              ],
            ),
    );
  }
}
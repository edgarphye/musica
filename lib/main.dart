import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/application/player_controller.dart';
import 'src/application/theme_controller.dart';
import 'src/ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ensurePlaybackEngine();
  final savedTheme = await loadSavedTheme();
  runApp(
    ProviderScope(
      overrides: [
        themeControllerProvider.overrideWith(() => ThemeController(initial: savedTheme)),
      ],
      child: const MusicaApp(),
    ),
  );
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/application/player_controller.dart';
import 'src/ui/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ensurePlaybackEngine();
  runApp(const ProviderScope(child: MusicaApp()));
}
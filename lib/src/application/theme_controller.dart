import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../ui/themes.dart';

final themeControllerProvider =
    NotifierProvider<ThemeController, AppTheme>(ThemeController.new);

class ThemeController extends Notifier<AppTheme> {
  ThemeController({this.initial = AppTheme.lavanda});

  final AppTheme initial;

  @override
  AppTheme build() => initial;

  Future<void> setTheme(AppTheme theme) async {
    if (theme == state) return;
    state = theme;
    await save();
  }

  Future<void> save() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/settings.json');
      await file.writeAsString(jsonEncode({'theme': state.name}));
    } catch (_) {
      // El guardado es opcional: el tema se mantiene durante la sesión.
    }
  }
}

Future<AppTheme> loadSavedTheme() async {
  try {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/settings.json');
    if (await file.exists()) {
      final data = jsonDecode(await file.readAsString());
      final name = data['theme'] as String?;
      if (name != null) {
        for (final t in AppTheme.values) {
          if (t.name == name) return t;
        }
      }
    }
  } catch (_) {}
  return AppTheme.lavanda;
}
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Cierra la aplicación de forma elegante en cada plataforma.
Future<void> closeApplication() async {
  if (kIsWeb) {
    return;
  }
  if (defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    exit(0);
  } else {
    await SystemNavigator.pop();
  }
}
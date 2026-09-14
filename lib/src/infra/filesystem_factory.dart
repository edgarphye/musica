import 'dart:io';

import 'android_saf_filesystem.dart';
import 'desktop_filesystem.dart';
import 'filesystem_gateway.dart';

class FilesystemFactory {
  static FilesystemGateway create() {
    if (Platform.isAndroid) {
      return AndroidSafFilesystem();
    }
    return DesktopFilesystem();
  }
}
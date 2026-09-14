import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../domain/audio_file.dart';
import '../domain/folder.dart';
import 'filesystem_gateway.dart';

class DesktopFilesystem implements FilesystemGateway {
  @override
  Future<Folder?> pickSourceDirectory() async {
    final path = await FilePicker.getDirectoryPath(
      dialogTitle: 'Elegir carpeta de música',
    );
    if (path == null) return null;
    return Folder(id: path, name: p.basename(path));
  }

  @override
  Future<Folder?> pickDestinationDirectory() async {
    final path = await FilePicker.getDirectoryPath(
      dialogTitle: 'Elegir carpeta de destino',
    );
    if (path == null) return null;
    return Folder(id: path, name: p.basename(path));
  }

  @override
  Future<List<AudioFile>> scanAudioFiles(Folder folder) async {
    final root = Directory(folder.id);
    if (!await root.exists()) {
      return const <AudioFile>[];
    }
    final result = <AudioFile>[];
    await _walk(root, '', result);
    return result;
  }

  Future<void> _walk(
    Directory dir,
    String relativeDir,
    List<AudioFile> out,
  ) async {
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is Directory) {
        await _walk(entity, p.join(relativeDir, p.basename(entity.path)), out);
      } else if (entity is File) {
        final name = p.basename(entity.path);
        final file = AudioFile(
          id: entity.path,
          name: name,
          relativePath: p.join(relativeDir, name),
          contentUri: entity.path,
        );
        if (file.extensionIsAudio) {
          out.add(file);
        }
      }
    }
  }

  @override
  String inputArgument(AudioFile file) => file.contentUri ?? file.id;

  @override
  Future<String> outputPathFor(Folder destination, String relativePath) async {
    final full = p.join(destination.id, relativePath);
    await Directory(p.dirname(full)).create(recursive: true);
    return full;
  }

  @override
  Future<void> commitOutput(
    Folder destination,
    String relativePath,
    String scratchPath,
  ) async {
    final finalPath = await outputPathFor(destination, relativePath);
    if (p.normalize(finalPath) != p.normalize(scratchPath)) {
      await File(scratchPath).rename(finalPath);
    }
  }

  @override
  Future<bool> outputExists(Folder destination, String relativePath) async {
    return File(p.join(destination.id, relativePath)).exists();
  }

  @override
  Future<void> deleteFile(String path) async {
    final f = File(path);
    if (await f.exists()) {
      await f.delete();
    }
  }
}
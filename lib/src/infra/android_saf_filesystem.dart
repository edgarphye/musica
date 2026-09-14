import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/audio_file.dart';
import '../domain/folder.dart';
import 'filesystem_gateway.dart';

class AndroidSafFilesystem implements FilesystemGateway {
  static const _channel = MethodChannel('musica/saf');

  String _s(Object? v) => v?.toString() ?? '';

  @override
  Future<Folder?> pickSourceDirectory() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>('pickDirectory');
    if (result == null) return null;
    final uri = _s(result['uri']);
    final name = _s(result['name']);
    if (uri.isEmpty) return null;
    return Folder(id: uri, name: name.isEmpty ? 'Memoria USB' : name);
  }

  @override
  Future<Folder?> pickDestinationDirectory() => pickSourceDirectory();

  @override
  Future<List<AudioFile>> scanAudioFiles(Folder folder) async {
    final out = <AudioFile>[];
    await _walk(folder.id, '', out);
    return out;
  }

  Future<void> _walk(
    String treeUri,
    String relativeDir,
    List<AudioFile> out,
  ) async {
    final children = await _listChildren(treeUri, relativeDir);
    for (final child in children) {
      final isDir = child['isDirectory'] == true;
      final name = _s(child['name']);
      final uri = _s(child['uri']);
      final relPath = _s(child['relativePath']);
      if (uri.isEmpty || name.isEmpty) continue;
      if (isDir) {
        await _walk(treeUri, relPath, out);
      } else {
        final file = AudioFile(
          id: uri,
          name: name,
          relativePath: relPath,
          contentUri: uri,
        );
        if (file.extensionIsAudio) {
          out.add(file);
        }
      }
    }
  }

  Future<List<Map<String, Object?>>> _listChildren(
    String treeUri,
    String parentRelative,
  ) async {
    final raw = await _channel.invokeMethod<List<Object?>>('listChildren', {
      'uri': treeUri,
      'parentRelative': parentRelative,
    });
    if (raw == null) return const [];
    final out = <Map<String, Object?>>[];
    for (final e in raw) {
      if (e is Map) {
        out.add(e.map((k, v) => MapEntry(k.toString(), v)));
      } else {
        try {
          final decoded = jsonDecode(e.toString());
          if (decoded is Map) {
            out.add(decoded.map((k, v) => MapEntry(k.toString(), v)));
          }
        } catch (_) {}
      }
    }
    return out;
  }

  @override
  String inputArgument(AudioFile file) => file.contentUri ?? file.id;

  @override
  Future<String> outputPathFor(Folder destination, String relativePath) async {
    final cacheDir = await getTemporaryDirectory();
    final outDir = Directory('${cacheDir.path}/out');
    await outDir.create(recursive: true);
    return p.join(outDir.path, '${relativePath.hashCode}_${p.basename(relativePath)}');
  }

  @override
  Future<void> commitOutput(
    Folder destination,
    String relativePath,
    String scratchPath,
  ) async {
    final ok = await _channel.invokeMethod<bool>('writeFromPath', {
      'treeUri': destination.id,
      'relativePath': relativePath,
      'sourcePath': scratchPath,
    });
    await deleteFile(scratchPath);
    if (ok == false || ok == null) {
      throw StateError('No se pudo escribir el archivo en el destino.');
    }
  }

  @override
  Future<bool> outputExists(Folder destination, String relativePath) async {
    final exists = await _channel.invokeMethod<bool>('exists', {
      'treeUri': destination.id,
      'relativePath': relativePath,
    });
    return exists == true;
  }

  @override
  Future<void> deleteFile(String path) async {
    await _channel.invokeMethod<bool>('deleteCached', {'path': path});
  }
}
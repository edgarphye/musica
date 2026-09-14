import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:musica/src/domain/folder.dart';
import 'package:musica/src/infra/desktop_filesystem.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('musica_scan_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  Future<void> writeFile(String rel) async {
    final f = File(p.join(tempDir.path, rel));
    await f.create(recursive: true);
  }

  test('escanea recursivamente y filtra por extensiones de audio', () async {
    await writeFile('canciones/a.flac');
    await writeFile('canciones/subdir/b.wav');
    await writeFile('canciones/subdir/notas.txt');
    await writeFile('canciones/subdir/img.png');
    await writeFile('canciones/c.mp3');
    await writeFile('leeme.txt');

    final fs = DesktopFilesystem();
    final folder = Folder(id: tempDir.path, name: 'origen');
    final files = await fs.scanAudioFiles(folder);

    expect(files.map((f) => f.name).toSet(), {'a.flac', 'b.wav', 'c.mp3'});
    expect(files.length, 3);
  });

  test('acepta extensiones en mayúsculas', () async {
    await writeFile('canciones/GRABACION.OGG');

    final fs = DesktopFilesystem();
    final folder = Folder(id: tempDir.path, name: 'origen');
    final files = await fs.scanAudioFiles(folder);

    expect(files.length, 1);
    expect(files.single.extensionIsAudio, isTrue);
  });

  test('devuelve lista vacía para una carpeta sin audio o inexistente', () async {
    final fs = DesktopFilesystem();

    final files = await fs.scanAudioFiles(
      Folder(id: tempDir.path, name: 'origen'),
    );
    expect(files, isEmpty);

    final missing = await fs.scanAudioFiles(
      Folder(id: p.join(tempDir.path, 'no_existe'), name: 'origen'),
    );
    expect(missing, isEmpty);
  });
}
import 'package:flutter_test/flutter_test.dart';

import 'package:musica/src/domain/conversion_profile.dart';
import 'package:musica/src/infra/ffmpeg_engine.dart';

void main() {
  group('buildCommandArgs', () {
    test('perfil MP3 genera los argumentos exactos', () {
      final args = FfmpegEngine.buildCommandArgs(
        input: '/origen/cancion.flac',
        outputPath: '/destino/cancion.mp3',
        profile: const ConversionProfile(format: OutputFormat.mp3),
      );

      expect(args, [
        '-y',
        '-i',
        '/origen/cancion.flac',
        '-map',
        '0:a',
        '-map_metadata',
        '0',
        '-c:a',
        'libmp3lame',
        '-b:a',
        '192k',
        '-id3v2_version',
        '3',
        '-write_id3v1',
        '1',
        '/destino/cancion.mp3',
      ]);
    });

    test('perfil M4A genera los argumentos exactos', () {
      final args = FfmpegEngine.buildCommandArgs(
        input: '/origen/cancion.wav',
        outputPath: '/destino/cancion.m4a',
        profile: const ConversionProfile(format: OutputFormat.m4a),
      );

      expect(args, [
        '-y',
        '-i',
        '/origen/cancion.wav',
        '-map',
        '0:a',
        '-map_metadata',
        '0',
        '-c:a',
        'aac',
        '-b:a',
        '192k',
        '-f',
        'mp4',
        '-movflags',
        '+faststart',
        '/destino/cancion.m4a',
      ]);
    });

    test('respeta el bitrate configurado', () {
      final args = FfmpegEngine.buildCommandArgs(
        input: 'in.flac',
        outputPath: 'out.mp3',
        profile: const ConversionProfile(
          format: OutputFormat.mp3,
          bitrate: 320,
        ),
      );

      expect(args, contains('-b:a'));
      expect(args[args.indexOf('-b:a') + 1], '320k');
    });
  });
}
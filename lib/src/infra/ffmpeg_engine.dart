import 'dart:async';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_audio/statistics.dart';

import '../domain/conversion_profile.dart';

class FfmpegProgress {
  const FfmpegProgress({
    required this.sessionId,
    required this.timeMs,
    required this.durationMs,
  });

  final int sessionId;
  final int timeMs;
  final int durationMs;

  double get fraction {
    if (durationMs <= 0) return 0;
    return (timeMs / durationMs).clamp(0.0, 1.0);
  }

  int get percent => (fraction * 100).round();
}

class FfmpegResult {
  const FfmpegResult({required this.success, required this.cancelled, this.error});

  final bool success;
  final bool cancelled;
  final String? error;
}

class FfmpegEngine {
  FfmpegEngine() {
    FFmpegKitConfig.enableStatisticsCallback(_onStatistics);
  }

  int? _activeSessionId;
  final _statStream = StreamController<FfmpegProgress>.broadcast();
  Stream<FfmpegProgress> get statistics => _statStream.stream;

  void _onStatistics(Statistics statistics) {
    final sessionId = statistics.getSessionId();
    if (_activeSessionId == null) return;
    if (sessionId != _activeSessionId) return;
    _statStream.add(
      FfmpegProgress(
        sessionId: _activeSessionId!,
        timeMs: statistics.getTime(),
        durationMs: _durationMs,
      ),
    );
  }

  int _durationMs = 0;

  /// Obtiene la duración (ms) de un archivo con FFprobe.
  /// Devuelve 0 si no se puede determinar.
  Future<int> probeDuration(String input) async {
    try {
      final session = await FFprobeKit.getMediaInformation(input);
      final info = session.getMediaInformation();
      final durationString = info?.getDuration();
      if (durationString == null) return 0;
      final seconds = double.tryParse(durationString);
      if (seconds == null || seconds <= 0) return 0;
      return (seconds * 1000).round();
    } catch (_) {
      return 0;
    }
  }

  /// Convierte [input] a [outputPath] con el perfil dado.
  Future<FfmpegResult> convert({
    required String input,
    required String outputPath,
    required ConversionProfile profile,
  }) async {
    final args = buildCommandArgs(
      input: input,
      outputPath: outputPath,
      profile: profile,
    );

    _durationMs = await probeDuration(input);

    Completer<FfmpegResult> completer = Completer();
    try {
      final session = await FFmpegKit.executeWithArgumentsAsync(
        args,
        (session) async {
          final rc = await session.getReturnCode();
          final result = FfmpegResult(
            success: ReturnCode.isSuccess(rc),
            cancelled: ReturnCode.isCancel(rc),
            error: ReturnCode.isSuccess(rc) || ReturnCode.isCancel(rc)
                ? null
                : 'Código de error FFmpeg: ${rc?.getValue()}',
          );
          if (!completer.isCompleted) completer.complete(result);
        },
      );
      _activeSessionId = session.getSessionId();
      final result = await completer.future.timeout(
        const Duration(minutes: 60),
        onTimeout: () {
          FFmpegKit.cancel();
          return const FfmpegResult(
            success: false,
            cancelled: true,
            error: 'Se agotó el tiempo de conversión',
          );
        },
      );
      return result;
    } catch (e) {
      return FfmpegResult(success: false, cancelled: false, error: e.toString());
    } finally {
      _activeSessionId = null;
    }
  }

  /// Cancela la conversión activa.
  Future<void> cancelActive() async {
    final sessionId = _activeSessionId;
    if (sessionId != null) {
      await FFmpegKit.cancel(sessionId);
    } else {
      await FFmpegKit.cancel();
    }
  }

  /// Construye los argumentos de FFmpeg según el perfil.
  static List<String> buildCommandArgs({
    required String input,
    required String outputPath,
    required ConversionProfile profile,
  }) {
    final common = <String>[
      '-y',
      '-i',
      input,
      '-map',
      '0:a',
      '-map_metadata',
      '0',
    ];

    List<String> codec;
    switch (profile.format) {
      case OutputFormat.mp3:
        codec = [
          '-c:a',
          'libmp3lame',
          '-b:a',
          '${profile.bitrate}k',
          '-id3v2_version',
          '3',
          '-write_id3v1',
          '1',
        ];
      case OutputFormat.m4a:
      case OutputFormat.mp4:
        codec = [
          '-c:a',
          'aac',
          '-b:a',
          '${profile.bitrate}k',
          '-f',
          'mp4',
          '-movflags',
          '+faststart',
        ];
    }

    return [...common, ...codec, outputPath];
  }
}
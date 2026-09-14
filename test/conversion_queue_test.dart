import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:musica/src/application/conversion_controller.dart';
import 'package:musica/src/domain/audio_file.dart';
import 'package:musica/src/domain/conversion_job.dart';
import 'package:musica/src/domain/conversion_profile.dart';
import 'package:musica/src/domain/folder.dart';
import 'package:musica/src/infra/ffmpeg_engine.dart';
import 'package:musica/src/infra/filesystem_gateway.dart';

class _FakeGateway implements FilesystemGateway {
  _FakeGateway({Set<String>? existingOutputs}) : existingOutputs = {...?existingOutputs};

  final Set<String> existingOutputs;
  final List<String> savedOutputs = [];

  @override
  Future<Folder?> pickSourceDirectory() async => null;
  @override
  Future<Folder?> pickDestinationDirectory() async => null;
  @override
  Future<List<AudioFile>> scanAudioFiles(Folder folder) async => [];
  @override
  String inputArgument(AudioFile file) => file.contentUri ?? file.id;
  @override
  Future<String> outputPathFor(Folder destination, String relativePath) async =>
      'scratch:$relativePath';
  @override
  Future<void> commitOutput(
    Folder destination,
    String relativePath,
    String scratchPath,
  ) async {
    savedOutputs.add(relativePath);
  }

  @override
  Future<bool> outputExists(Folder destination, String relativePath) async =>
      existingOutputs.contains(relativePath);

  @override
  Future<void> deleteFile(String path) async {}
}

class _FakeEngine extends FfmpegEngine {
  _FakeEngine({List<FfmpegResult>? results})
      : results = results ?? const [_ok];

  static const _ok = FfmpegResult(success: true, cancelled: false);

  final List<FfmpegResult> results;
  final StreamController<FfmpegProgress> _stats =
      StreamController<FfmpegProgress>.broadcast();

  int callCount = 0;
  Completer<FfmpegResult>? pending;
  bool cancelCalled = false;

  @override
  Stream<FfmpegProgress> get statistics => _stats.stream;

  @override
  Future<FfmpegResult> convert({
    required String input,
    required String outputPath,
    required ConversionProfile profile,
  }) async {
    if (pending != null) {
      final result = await pending!.future;
      _stats.add(const FfmpegProgress(sessionId: 1, timeMs: 1000, durationMs: 1000));
      return result;
    }
    final result = callCount < results.length ? results[callCount] : _ok;
    callCount++;
    _stats.add(const FfmpegProgress(sessionId: 1, timeMs: 1000, durationMs: 1000));
    return result;
  }

  @override
  Future<void> cancelActive() async {
    cancelCalled = true;
  }
}

AudioFile _file(String name) => AudioFile(
      id: '/origen/$name',
      name: name,
      relativePath: name,
      contentUri: '/origen/$name',
    );

void main() {
  final destination = Folder(id: '/destino', name: 'destino');
  final profile = const ConversionProfile(format: OutputFormat.mp3);

  group('prepare / políticas de sobrescritura', () {
    test('marca como skipped los archivos que ya existen (política Saltar)',
        () async {
      final gateway = _FakeGateway(existingOutputs: {'a.mp3'});
      final controller = ConversionController(
        filesystem: gateway,
        engine: _FakeEngine(),
      );

      await controller.prepare(
        [_file('a.flac'), _file('b.flac')],
        destination: destination,
        profile: profile,
        overwritePolicy: const OverwriteSkip(),
      );

      final jobs = controller.state.jobs;
      expect(jobs[0].status, JobStatus.skipped);
      expect(jobs[0].message, 'Ya existe en el destino');
      expect(jobs[1].status, JobStatus.pending);
      expect(controller.state.skipped, 1);
      expect(controller.state.total, 2);
    });

    test('renombra (N) los existentes (política Renombrar)', () async {
      final gateway = _FakeGateway(existingOutputs: {'a.mp3'});
      final controller = ConversionController(
        filesystem: gateway,
        engine: _FakeEngine(),
      );

      await controller.prepare(
        [_file('a.flac')],
        destination: destination,
        profile: profile,
        overwritePolicy: const OverwriteRename(),
      );

      final job = controller.state.jobs.single;
      expect(job.status, JobStatus.pending);
      expect(job.outputRelativePath, 'a (1).mp3');
    });

    test('renombra incrementando hasta encontrar un nombre libre', () async {
      final gateway = _FakeGateway(existingOutputs: {'a.mp3', 'a (1).mp3'});
      final controller = ConversionController(
        filesystem: gateway,
        engine: _FakeEngine(),
      );

      await controller.prepare(
        [_file('a.flac')],
        destination: destination,
        profile: profile,
        overwritePolicy: const OverwriteRename(),
      );

      expect(controller.state.jobs.single.outputRelativePath, 'a (2).mp3');
    });

    test('no renombra ni saltan con OverwriteAlways', () async {
      final gateway = _FakeGateway(existingOutputs: {'a.mp3'});
      final controller = ConversionController(
        filesystem: gateway,
        engine: _FakeEngine(),
      );

      await controller.prepare(
        [_file('a.flac')],
        destination: destination,
        profile: profile,
        overwritePolicy: const OverwriteAlways(),
      );

      final job = controller.state.jobs.single;
      expect(job.status, JobStatus.pending);
      expect(job.outputRelativePath, 'a.mp3');
    });
  });

  group('cola de conversión', () {
    test('procesa secuencialmente y termina con todos done', () async {
      final controller = ConversionController(
        filesystem: _FakeGateway(),
        engine: _FakeEngine(results: [_okNow(), _okNow()]),
      );

      await controller.prepare(
        [_file('a.flac'), _file('b.wav')],
        destination: destination,
        profile: profile,
        overwritePolicy: const OverwriteAlways(),
      );
      await controller.start();

      final state = controller.state;
      expect(state.done, 2);
      expect(state.errors, 0);
      expect(state.running, isFalse);
      expect(state.finished, isTrue);
      expect(state.overallProgress, 1.0);
    });

    test('un archivo con error no detiene la cola', () async {
      final controller = ConversionController(
        filesystem: _FakeGateway(),
        engine: _FakeEngine(
          results: [
            const FfmpegResult(success: false, cancelled: false, error: 'boom'),
            _okNow(),
          ],
        ),
      );

      await controller.prepare(
        [_file('a.flac'), _file('b.wav')],
        destination: destination,
        profile: profile,
        overwritePolicy: const OverwriteAlways(),
      );
      await controller.start();

      final state = controller.state;
      expect(state.errors, 1);
      expect(state.done, 1);
      expect(state.finished, isTrue);
      expect(state.jobs[0].message, 'boom');
    });

    test('los trabajos skipped no se convierten', () async {
      final controller = ConversionController(
        filesystem: _FakeGateway(existingOutputs: {'a.mp3'}),
        engine: _FakeEngine(results: [_okNow()]),
      );

      await controller.prepare(
        [_file('a.flac'), _file('b.wav')],
        destination: destination,
        profile: profile,
        overwritePolicy: const OverwriteSkip(),
      );
      await controller.start();

      final state = controller.state;
      expect(state.skipped, 1);
      expect(state.done, 1);
      expect(state.finished, isTrue);
    });

    test('cancelación global descarta pendientes y el actual', () async {
      final engine = _FakeEngine();
      engine.pending = Completer<FfmpegResult>();
      final controller = ConversionController(
        filesystem: _FakeGateway(),
        engine: engine,
      );

      await controller.prepare(
        [_file('a.flac'), _file('b.wav'), _file('c.ogg')],
        destination: destination,
        profile: profile,
        overwritePolicy: const OverwriteAlways(),
      );

      final running = controller.start();
      await Future<void>.delayed(Duration.zero);
      await controller.cancel();
      engine.pending!.complete(
        const FfmpegResult(success: false, cancelled: true, error: null),
      );
      await running;

      final state = controller.state;
      expect(state.cancelled, isTrue);
      expect(state.cancelledCount, 3);
      expect(state.running, isFalse);
      expect(state.finished, isTrue);
    });

    test('commitOutput solo se llama en archivos correctos', () async {
      final gateway = _FakeGateway();
      final controller = ConversionController(
        filesystem: gateway,
        engine: _FakeEngine(results: [_okNow(), _okNow()]),
      );

      await controller.prepare(
        [_file('a.flac')],
        destination: destination,
        profile: profile,
        overwritePolicy: const OverwriteAlways(),
      );
      await controller.start();

      expect(gateway.savedOutputs, ['a.mp3']);
    });
  });
}

FfmpegResult _okNow() =>
    const FfmpegResult(success: true, cancelled: false);
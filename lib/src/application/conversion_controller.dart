import 'dart:async';

import '../domain/audio_file.dart';
import '../domain/conversion_job.dart';
import '../domain/conversion_profile.dart';
import '../domain/folder.dart';
import '../infra/filesystem_gateway.dart';
import '../infra/ffmpeg_engine.dart';

class ConversionState {
  const ConversionState({
    this.jobs = const [],
    this.running = false,
    this.finished = false,
    this.cancelled = false,
  });

  final List<ConversionJob> jobs;
  final bool running;
  final bool finished;
  final bool cancelled;

  int get total => jobs.length;
  int get done => jobs.where((j) => j.status == JobStatus.done).length;
  int get errors => jobs.where((j) => j.status == JobStatus.error).length;
  int get skipped => jobs.where((j) => j.status == JobStatus.skipped).length;
  int get cancelledCount => jobs.where((j) => j.status == JobStatus.cancelled).length;

  double get overallProgress {
    if (jobs.isEmpty) return 0;
    var sum = 0.0;
    for (final j in jobs) {
      switch (j.status) {
        case JobStatus.done:
          sum += 1;
        case JobStatus.skipped:
          sum += 1;
        case JobStatus.cancelled:
          sum += 0;
        case JobStatus.error:
          sum += 0;
        case JobStatus.pending:
          sum += 0;
        case JobStatus.converting:
          sum += j.progress;
      }
    }
    return sum / jobs.length;
  }
}

class ConversionController {
  ConversionController({
    required this.filesystem,
    required this.engine,
  });

  final FilesystemGateway filesystem;
  final FfmpegEngine engine;

  ConversionProfile profile = const ConversionProfile(format: OutputFormat.mp3);
  OverwritePolicy overwrite = const OverwriteSkip();
  Folder? _destination;

  final _stateController = StreamController<ConversionState>.broadcast();
  Stream<ConversionState> get stateStream => _stateController.stream;
  ConversionState _state = const ConversionState();
  ConversionState get state => _state;

  bool _cancelling = false;

  /// Prepara la cola a partir de los archivos escaneados.
  List<ConversionJob> buildJobs(List<AudioFile> files) {
    return files
        .map(
          (f) => ConversionJob(
            id: f.id,
            file: f,
            outputRelativePath: _relativeOutputName(f, ''),
          ),
        )
        .toList();
  }

  String _relativeOutputName(AudioFile f, String suffix) {
    final ext = profile.format.extension;
    final name = '${f.baseName}$suffix.$ext';
    return f.parentPath.isEmpty ? name : '${f.parentPath}/$name';
  }

  /// Establece el destino y filtra los trabajos ya existentes según política.
  Future<void> prepare(
    List<AudioFile> files, {
    required Folder destination,
    required ConversionProfile profile,
    required OverwritePolicy overwritePolicy,
  }) async {
    _destination = destination;
    this.profile = profile;
    overwrite = overwritePolicy;

    var jobs = buildJobs(files);

    var adjusted = <ConversionJob>[];
    for (final job in jobs) {
      final exists = await filesystem.outputExists(
        destination,
        job.outputRelativePath,
      );
      if (!exists) {
        adjusted.add(job);
        continue;
      }
      var adjustedJob = job;
      if (overwritePolicy is OverwriteSkip) {
        adjustedJob = job.copyWith(
          status: JobStatus.skipped,
          message: 'Ya existe en el destino',
        );
      } else if (overwritePolicy is OverwriteRename) {
        var n = 1;
        var candidate = _renameSuffix(job.file, profile, n);
        while (await filesystem.outputExists(
          destination,
          candidate,
        )) {
          n++;
          candidate = _renameSuffix(job.file, profile, n);
        }
        adjustedJob = ConversionJob(
          id: job.id,
          file: job.file,
          outputRelativePath: candidate,
        );
      }
      // OverwriteAlways: se sobrescribe (FFmpeg usa -y)
      adjusted.add(adjustedJob);
    }

    _state = ConversionState(jobs: adjusted, running: false, finished: false);
    _emit();
  }

  String _renameSuffix(AudioFile f, ConversionProfile profile, int n) {
    final ext = profile.format.extension;
    final name = '${f.baseName} ($n).$ext';
    return f.parentPath.isEmpty ? name : '${f.parentPath}/$name';
  }

  Future<void> start() async {
    if (_state.running) return;

    final jobs = _state.jobs;
    _state = ConversionState(jobs: jobs, running: true);
    _emit();

    for (var i = 0; i < jobs.length; i++) {
      final job = jobs[i];
      if (_cancelling) break;
      if (job.status == JobStatus.skipped ||
          job.status == JobStatus.cancelled ||
          job.status == JobStatus.done) {
        continue;
      }

      job.status = JobStatus.converting;
      job.progress = 0;
      job.message = null;
      _emit();

      String? scratchPath;
      try {
        scratchPath = await filesystem.outputPathFor(
          _destination!,
          job.outputRelativePath,
        );

        final sub = engine.statistics.listen((p) {
          job.progress = p.fraction;
          _emit();
        });

        final input = filesystem.inputArgument(job.file);
        final result = await engine.convert(
          input: input,
          outputPath: scratchPath,
          profile: profile,
        );

        await sub.cancel();

        if (result.cancelled) {
          job.status = JobStatus.cancelled;
          job.message = 'Cancelado';
          await filesystem.deleteFile(scratchPath);
        } else if (result.success) {
          await filesystem.commitOutput(
            _destination!,
            job.outputRelativePath,
            scratchPath,
          );
          job.status = JobStatus.done;
          job.progress = 1;
        } else {
          job.status = JobStatus.error;
          job.message = result.error ?? 'Error desconocido';
          await filesystem.deleteFile(scratchPath);
        }
        _emit();
      } catch (e) {
        job.status = JobStatus.error;
        job.message = e.toString();
        if (scratchPath != null) {
          await filesystem.deleteFile(scratchPath);
        }
        _emit();
      }
    }

    final wasCancelling = _cancelling;
    _cancelling = false;
    _state = ConversionState(
      jobs: _state.jobs,
      running: false,
      finished: true,
      cancelled: wasCancelling,
    );
    _emit();
  }

  Future<void> cancel() async {
    _cancelling = true;
    await engine.cancelActive();
    for (final job in _state.jobs) {
      if (job.status == JobStatus.pending) {
        job.status = JobStatus.cancelled;
        job.message = 'Cancelado por el usuario';
      }
    }
    _emit();
  }

  Future<void> cancelJob(String id) async {
    final job = _state.jobs.firstWhere((j) => j.id == id);
    if (job.status == JobStatus.converting) {
      await engine.cancelActive();
      job.status = JobStatus.cancelled;
      job.message = 'Cancelado por el usuario';
      _emit();
    } else if (job.status == JobStatus.pending) {
      job.status = JobStatus.cancelled;
      job.message = 'Cancelado por el usuario';
      _emit();
    }
  }

  void _emit() {
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  void dispose() {
    _stateController.close();
  }
}
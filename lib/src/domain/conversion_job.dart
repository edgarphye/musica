import 'audio_file.dart';

enum JobStatus { pending, converting, done, error, cancelled, skipped }

class ConversionJob {
  ConversionJob({
    required this.id,
    required this.file,
    required this.outputRelativePath,
    this.status = JobStatus.pending,
    this.progress = 0,
    this.message,
  });

  final String id;
  final AudioFile file;
  final String outputRelativePath;
  JobStatus status;
  double progress;
  String? message;

  ConversionJob copyWith({
    JobStatus? status,
    double? progress,
    String? message,
  }) {
    return ConversionJob(
      id: id,
      file: file,
      outputRelativePath: outputRelativePath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      message: message,
    );
  }
}
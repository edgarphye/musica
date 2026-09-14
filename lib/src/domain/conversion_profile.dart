enum OutputFormat { mp3, m4a, mp4 }

extension OutputFormatX on OutputFormat {
  String get label => switch (this) {
        OutputFormat.mp3 => 'MP3',
        OutputFormat.m4a => 'AAC / M4A',
        OutputFormat.mp4 => 'MP4',
      };

  String get extension => switch (this) {
        OutputFormat.mp3 => 'mp3',
        OutputFormat.m4a => 'm4a',
        OutputFormat.mp4 => 'mp4',
      };
}

class ConversionProfile {
  const ConversionProfile({required this.format, this.bitrate = 192});

  final OutputFormat format;
  final int bitrate;
}

sealed class OverwritePolicy {
  const OverwritePolicy();

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class OverwriteAlways extends OverwritePolicy {
  const OverwriteAlways();
}

class OverwriteSkip extends OverwritePolicy {
  const OverwriteSkip();
}

class OverwriteRename extends OverwritePolicy {
  const OverwriteRename();
}
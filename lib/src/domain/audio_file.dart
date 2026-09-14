enum AudioSourcePlatform { android, desktop }

class AudioFile {
  const AudioFile({
    required this.id,
    required this.name,
    required this.relativePath,
    this.contentUri,
  });

  final String id;
  final String name;
  final String relativePath;
  final String? contentUri;

  static const audioExtensions = {
    '.flac', '.wav', '.ogg', '.oga', '.opus', '.wma', '.aiff', '.aif',
    '.ape', '.m4a', '.aac', '.mp3', '.mp2', '.alac', '.amr', '.mid',
    '.midi', '.mka', '.ra', '.wv',
  };

  bool get extensionIsAudio => audioExtensions.contains(extension);

  String get extension {
    final idx = name.lastIndexOf('.');
    return idx < 0 ? '' : name.substring(idx).toLowerCase();
  }

  String get baseName {
    final idx = name.lastIndexOf('.');
    return idx < 0 ? name : name.substring(0, idx);
  }

  String get parentPath {
    final idx = relativePath.lastIndexOf('/');
    return idx < 0 ? '' : relativePath.substring(0, idx);
  }
}
import '../domain/audio_file.dart';

class Track {
  const Track({
    required this.file,
    required this.folder,
    this.durationMs = 0,
  });

  final AudioFile file;
  final String folder;
  final int durationMs;

  String get title {
    final base = file.baseName;
    final parts = base.split(' - ');
    return parts.length >= 2 ? parts.sublist(1).join(' - ').trim() : base;
  }

  String get artist {
    final base = file.baseName;
    final parts = base.split(' - ');
    if (parts.length >= 2) return parts.first.trim();
    // primer segmento de la ruta como artista/álbum
    final seg = file.parentPath.split('/').where((s) => s.isNotEmpty).toList();
    return seg.isNotEmpty ? seg.last : file.name;
  }

  String get album {
    final seg = file.parentPath.split('/').where((s) => s.isNotEmpty).toList();
    return seg.isNotEmpty ? seg.last : 'Álbum desconocido';
  }
}

class MusicLibrary {
  const MusicLibrary(this.tracks);

  final List<Track> tracks;

  List<Track> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return tracks;
    return tracks
        .where(
          (t) =>
              t.title.toLowerCase().contains(q) ||
              t.artist.toLowerCase().contains(q) ||
              t.album.toLowerCase().contains(q) ||
              t.file.name.toLowerCase().contains(q),
        )
        .toList();
  }

  Map<String, List<Track>> groupByFolder() {
    final map = <String, List<Track>>{};
    for (final t in tracks) {
      map.putIfAbsent(t.folder, () => []).add(t);
    }
    return map;
  }
}
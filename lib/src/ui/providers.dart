import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/conversion_controller.dart';
import '../application/player_controller.dart';
import '../domain/folder.dart';
import '../domain/music_library.dart';
import '../infra/ffmpeg_engine.dart';
import '../infra/filesystem_factory.dart';
import '../infra/filesystem_gateway.dart';

final filesystemProvider = Provider<FilesystemGateway>((ref) {
  return FilesystemFactory.create();
});

final ffmpegEngineProvider = Provider<FfmpegEngine>((ref) {
  return FfmpegEngine();
});

/// Controlador de conversión expuesto como provider (usa Stream internamente;
/// la UI se suscribe con StreamBuilder).
final conversionControllerProvider = Provider<ConversionController>((ref) {
  final controller = ConversionController(
    filesystem: ref.watch(filesystemProvider),
    engine: ref.watch(ffmpegEngineProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

/// Reproductor expuesto como provider.
final playerControllerProvider = Provider<PlayerController>((ref) {
  final controller = PlayerController();
  ref.onDispose(controller.dispose);
  return controller;
});

// ---- Estado de la biblioteca / explorar de la USB ----

class LibraryState {
  const LibraryState({
    this.source,
    this.library = const MusicLibrary([]),
    this.query = '',
    this.loading = false,
    this.error,
  });

  final Folder? source;
  final MusicLibrary library;
  final String query;
  final bool loading;
  final String? error;

  LibraryState copyWith({
    Folder? source,
    MusicLibrary? library,
    String? query,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return LibraryState(
      source: source ?? this.source,
      library: library ?? this.library,
      query: query ?? this.query,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LibraryNotifier extends Notifier<LibraryState> {
  @override
  LibraryState build() => const LibraryState();

  Future<void> pickSource() async {
    final fs = ref.read(filesystemProvider);
    final folder = await fs.pickSourceDirectory();
    if (folder == null) return;
    state = state.copyWith(source: folder, clearError: true);
    await scan(folder);
  }

  Future<void> scan(Folder folder) async {
    final fs = ref.read(filesystemProvider);
    state = state.copyWith(loading: true, clearError: true);
    try {
      final files = await fs.scanAudioFiles(folder);
      final tracks = files
          .map((f) => Track(file: f, folder: f.parentPath))
          .toList();
      state = state.copyWith(library: MusicLibrary(tracks), loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }
}

final libraryProvider =
    NotifierProvider<LibraryNotifier, LibraryState>(LibraryNotifier.new);
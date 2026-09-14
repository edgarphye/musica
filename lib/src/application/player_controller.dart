import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import '../domain/audio_file.dart';
import '../domain/music_library.dart';

class PlayerState {
  const PlayerState({
    this.currentTrack,
    this.queue = const [],
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.isLoading = false,
    this.error,
  });

  final Track? currentTrack;
  final List<Track> queue;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isLoading;
  final String? error;

  PlayerState copyWith({
    Track? currentTrack,
    bool? clearTrack,
    List<Track>? queue,
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    bool? isLoading,
    String? error,
  }) {
    return PlayerState(
      currentTrack: clearTrack == true ? null : (currentTrack ?? this.currentTrack),
      queue: queue ?? this.queue,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PlayerController {
  PlayerController() {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();
  final _stateController = StreamController<PlayerState>.broadcast();
  Stream<PlayerState> get stateStream => _stateController.stream;
  PlayerState _state = const PlayerState();
  PlayerState get state => _state;

  List<Track> _queue = [];
  int _index = -1;
  int _playlistId = 0;
  final _subscriptions = <StreamSubscription>[];

  void _init() {
    _subscriptions.add(
      _player.playerStateStream.listen(
        (ps) {
          _state = _state.copyWith(
            isPlaying: ps.playing,
            isLoading: ps.processingState == ProcessingState.loading,
          );
          _emit();
        },
        onError: (Object e) {
          _state = _state.copyWith(
            error: 'Error reproduciendo el archivo.',
          );
          _emit();
        },
      ),
    );
    _subscriptions.add(
      _player.positionStream.listen((pos) {
        _state = _state.copyWith(position: pos);
        _emit();
      }),
    );
    _subscriptions.add(
      _player.durationStream.listen((dur) {
        _state = _state.copyWith(
          duration: dur ?? Duration.zero,
        );
        _emit();
      }),
    );
    _subscriptions.add(
      _player.sequenceStateStream.listen((seq) {
        final idx = seq.currentIndex;
        if (idx != null && idx >= 0 && idx < _queue.length) {
          _index = idx;
          _state = _state.copyWith(currentTrack: _queue[idx]);
          _emit();
        }
      }),
    );
  }

  /// Reproduce la lista completa a partir de [startIndex].
  Future<void> playQueue(List<Track> queue, int startIndex) async {
    if (queue.isEmpty) return;
    _queue = List.of(queue);
    _index = startIndex.clamp(0, queue.length - 1);
    _playlistId++;

    final thisId = _playlistId;
    try {
      final sources = [
        for (final t in _queue) AudioSource.uri(_uriFor(t.file), tag: t),
      ];

      _state = _state.copyWith(
        queue: _queue,
        currentTrack: _queue[_index],
        error: null,
      );
      _emit();

      await _player.setAudioSources(
        sources,
        initialIndex: _index,
      );
      if (thisId != _playlistId) return;
      _player.play();
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      _emit();
    }
  }

  Uri _uriFor(AudioFile f) {
    final source = f.contentUri ?? f.id;
    final uri = Uri.tryParse(source);
    if (uri != null && uri.hasScheme) return uri;
    return Uri.file(source);
  }

  Future<void> togglePlayPause() async {
    if (_state.queue.isEmpty && _state.currentTrack == null) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    if (_index < _queue.length - 1) {
      await _player.seekToNext();
    } else {
      await _player.seek(Duration.zero, index: 0);
    }
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
    } else {
      await _player.seekToPrevious();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> stop() async {
    await _player.stop();
    _state = _state.copyWith(
      clearTrack: true,
      isPlaying: false,
      position: Duration.zero,
      duration: Duration.zero,
    );
    _emit();
  }

  void _emit() {
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _player.dispose();
    _stateController.close();
  }
}

/// Inicializa el playback para Windows/Linux (media_kit). Android usa el
/// motor nativo de just_audio.
void ensurePlaybackEngine() {
  JustAudioMediaKit.ensureInitialized();
}
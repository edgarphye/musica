import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class PlayerBar extends ConsumerWidget {
  const PlayerBar({super.key});

  String _fmt(Duration d) {
    final total = d.inSeconds;
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerControllerProvider);
    final state = player.state;
    final track = state.currentTrack;
    if (track == null) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;

    final duration = state.duration;
    final position =
        state.position > duration ? Duration.zero : state.position;
    final maxMs = duration.inMilliseconds.toDouble().clamp(1.0, double.infinity);

    return Material(
      color: colors.surfaceContainer,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            children: [
              _Artwork(track: track, size: 42),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _fmt(position),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape:
                                  const RoundSliderOverlayShape(overlayRadius: 12),
                            ),
                            child: Slider(
                              value: position.inMilliseconds
                                  .clamp(0, maxMs.toInt())
                                  .toDouble(),
                              max: maxMs,
                              onChanged: (v) {
                                if (state.duration > Duration.zero) {
                                  player.seek(Duration(milliseconds: v.round()));
                                }
                              },
                            ),
                          ),
                        ),
                        Text(
                          _fmt(duration),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Anterior',
                icon: const Icon(Icons.skip_previous),
                onPressed: () => player.previous(),
              ),
              IconButton.filled(
                tooltip: state.isPlaying ? 'Pausa' : 'Reproducir',
                icon: Icon(
                  state.isLoading
                      ? Icons.hourglass_top
                      : state.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                ),
                onPressed: () => player.togglePlayPause(),
              ),
              IconButton(
                tooltip: 'Siguiente',
                icon: const Icon(Icons.skip_next),
                onPressed: () => player.next(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.track, required this.size});

  final dynamic track;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.tertiary],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.music_note, color: Colors.white),
    );
  }
}
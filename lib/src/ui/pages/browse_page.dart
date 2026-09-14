import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/player_controller.dart';
import '../../domain/music_library.dart';
import '../providers.dart';

class BrowsePage extends ConsumerStatefulWidget {
  const BrowsePage({super.key});

  @override
  ConsumerState<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends ConsumerState<BrowsePage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _pickSource() {
    ref.read(libraryProvider.notifier).pickSource();
  }

  Future<void> _playList(List<Track> tracks, int index) async {
    final player = ref.read(playerControllerProvider);
    await player.playQueue(tracks, index);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryProvider);
    final colors = Theme.of(context).colorScheme;

    final results = state.library.search(state.query);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mi música',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Explora y escucha la música de tu USB o carpeta.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          _SourceHeader(
            source: state.source,
            loading: state.loading,
            onPick: _pickSource,
            error: state.error,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            enabled: state.source != null,
            onChanged: (v) {
              ref.read(libraryProvider.notifier).setQuery(v);
            },
            decoration: InputDecoration(
              hintText: 'Buscar canción, artista o álbum…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: state.query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(libraryProvider.notifier).setQuery('');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildBody(context, state, results),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    LibraryState state,
    List<Track> results,
  ) {
    if (state.source == null) {
      return _EmptyState(
        icon: Icons.usb,
        title: 'Conecta una USB o elige una carpeta',
        message:
            'Selecciona el origen para buscar y reproducir tu música al instante.',
        actionLabel: 'Elegir origen',
        onAction: _pickSource,
      );
    }

    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return _EmptyState(
        icon: Icons.error_outline,
        title: 'No se pudo leer el origen',
        message: state.error!,
        actionLabel: 'Intentar de nuevo',
        onAction: _pickSource,
      );
    }

    if (results.isEmpty) {
      return _EmptyState(
        icon: state.query.isEmpty ? Icons.music_off : Icons.search_off,
        title: state.query.isEmpty
            ? 'No se encontraron canciones'
            : 'Sin resultados para "${state.query}"',
        message: state.query.isEmpty
            ? 'El origen no contiene archivos de audio compatibles.'
            : 'Prueba con otro término de búsqueda.',
      );
    }

    return _TrackList(
      tracks: results,
      onChangeFolderSort: false,
      onPlay: (list, index) => _playList(list, index),
      player: ref.read(playerControllerProvider),
    );
  }
}

class _SourceHeader extends StatelessWidget {
  const _SourceHeader({
    required this.source,
    required this.loading,
    required this.onPick,
    this.error,
  });

  final dynamic source;
  final bool loading;
  final VoidCallback onPick;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasSource = source != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: hasSource ? colors.primaryContainer : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasSource ? Icons.check_circle : Icons.usb,
                color: hasSource ? colors.primary : colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasSource ? 'Origen conectado' : 'Sin origen',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (hasSource && source.name != null)
                    Text(
                      source.name!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  if (!hasSource && error != null)
                    Text(
                      error!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.error,
                          ),
                    ),
                ],
              ),
            ),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              FilledButton.tonalIcon(
                onPressed: onPick,
                icon: const Icon(Icons.folder_open, size: 18),
                label: Text(hasSource ? 'Cambiar' : 'Elegir'),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrackList extends ConsumerWidget {
  const _TrackList({
    required this.tracks,
    required this.onChangeFolderSort,
    required this.onPlay,
    required this.player,
  });

  final List<Track> tracks;
  final bool onChangeFolderSort;
  final void Function(List<Track> list, int index) onPlay;
  final PlayerController player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryProvider);

    // Agrupar por carpeta (álbum)
    final groups = <String, List<Track>>{};
    for (final t in tracks) {
      final key = t.folder.isEmpty ? 'Sin carpeta' : t.folder;
      groups.putIfAbsent(key, () => []).add(t);
    }
    final keys = groups.keys.toList()..sort();

    final currentTrackId = player.state.currentTrack?.file.id;

    return ListView(
      children: [
        if (tracks.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  '${tracks.length} canciones',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                if (state.query.isEmpty) ...[
                  const Spacer(),
                  IconButton(
                    tooltip: 'Reproducir todo',
                    icon: const Icon(Icons.play_circle_outline),
                    onPressed: () => onPlay(tracks, 0),
                  ),
                ],
              ],
            ),
          ),
        for (final key in keys)
          _FolderSection(
            folder: key,
            tracks: groups[key]!,
            currentTrackId: currentTrackId,
            onPlay: (list, index) => onPlay(list, index),
          ),
      ],
    );
  }
}

class _FolderSection extends StatelessWidget {
  const _FolderSection({
    required this.folder,
    required this.tracks,
    required this.currentTrackId,
    required this.onPlay,
  });

  final String folder;
  final List<Track> tracks;
  final String? currentTrackId;
  final void Function(List<Track> list, int index) onPlay;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final header = folder.split('/').where((s) => s.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Row(
              children: [
                Icon(Icons.album, size: 16, color: colors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    header.isEmpty ? 'Raíz' : header.last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                  ),
                ),
                Text(
                  '${tracks.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < tracks.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _TrackTile(
                    track: tracks[i],
                    isCurrent: tracks[i].file.id == currentTrackId,
                    indexInGroup: i,
                    onTap: () => onPlay(tracks, i),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackTile extends ConsumerWidget {
  const _TrackTile({
    required this.track,
    required this.isCurrent,
    required this.indexInGroup,
    required this.onTap,
  });

  final Track track;
  final bool isCurrent;
  final int indexInGroup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final player = ref.watch(playerControllerProvider);
    final isPlaying = isCurrent && player.state.isPlaying;

    return ListTile(
      onTap: onTap,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      leading: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.music_note, size: 20),
          ),
        ],
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          color: isCurrent ? colors.primary : null,
        ),
      ),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isCurrent
          ? Icon(
              isPlaying
                  ? Icons.graphic_eq
                  : Icons.play_circle_fill,
              color: colors.primary,
            )
          : IconButton(
              icon: const Icon(Icons.play_circle_outline),
              onPressed: onTap,
              color: colors.onSurfaceVariant,
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 36, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.folder_open),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
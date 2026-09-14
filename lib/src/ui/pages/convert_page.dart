import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/conversion_controller.dart';
import '../../domain/audio_file.dart';
import '../../domain/conversion_job.dart';
import '../../domain/conversion_profile.dart';
import '../../domain/folder.dart';
import '../providers.dart';

class ConvertPage extends ConsumerStatefulWidget {
  const ConvertPage({super.key});

  @override
  ConsumerState<ConvertPage> createState() => _ConvertPageState();
}

class _ConvertPageState extends ConsumerState<ConvertPage> {
  ConversionProfile _profile =
      const ConversionProfile(format: OutputFormat.mp3, bitrate: 192);
  OverwritePolicy _overwrite = const OverwriteSkip();
  Folder? _source;
  Folder? _destination;
  List<AudioFile> _pendingFiles = [];
  bool _scanning = false;
  String? _error;

  Future<void> _pickSource() async {
    final fs = ref.read(filesystemProvider);
    final folder = await fs.pickSourceDirectory();
    if (folder == null) return;
    setState(() {
      _source = folder;
      _error = null;
    });
    await _scan();
  }

  Future<void> _scan() async {
    final fs = ref.read(filesystemProvider);
    final src = _source;
    if (src == null) return;
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final files = await fs.scanAudioFiles(src);
      setState(() {
        _pendingFiles = files;
        _scanning = false;
      });
    } catch (e) {
      setState(() {
        _scanning = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _pickDestination() async {
    final fs = ref.read(filesystemProvider);
    final folder = await fs.pickDestinationDirectory();
    if (folder == null) return;
    setState(() => _destination = folder);
  }

  Future<void> _start() async {
    if (_source == null || _destination == null || _pendingFiles.isEmpty) return;

    final controller = ref.read(conversionControllerProvider);
    await controller.prepare(
      _pendingFiles,
      destination: _destination!,
      profile: _profile,
      overwritePolicy: _overwrite,
    );
    await controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final controller = ref.watch(conversionControllerProvider);
    final state = controller.state;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Convertir música',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Convierte FLAC, WAV, OGG y más a MP3 o AAC para que suenen en cualquier dispositivo.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          _SettingsCard(
            source: _source,
            destination: _destination,
            scanning: _scanning,
            onPickSource: _pickSource,
            onPickDestination: _pickDestination,
          ),
          const SizedBox(height: 12),
          _ProfileCard(
            profile: _profile,
            overwrite: _overwrite,
            onProfileChanged: (p) => setState(() => _profile = p),
            onOverwriteChanged: (o) => setState(() => _overwrite = o),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: colors.error),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed:
                state.running ? null : (_pendingFiles.isNotEmpty && _destination != null ? _start : null),
            icon: state.running
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(
              state.running
                  ? 'Convirtiendo…'
                  : 'Convertir ${_pendingFiles.length} ${_pendingFiles.length == 1 ? 'canción' : 'canciones'}',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _queueView(context, controller, state),
          ),
        ],
      ),
    );
  }

  Widget _queueView(
    BuildContext context,
    ConversionController controller,
    ConversionState state,
  ) {
    final jobs = state.jobs;
    if (jobs.isEmpty) {
      return Center(
        child: Text(
          'La cola de conversión aparecerá aquí.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    final donePct = (state.overallProgress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${state.done} de ${state.total} convertidas',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (state.errors > 0)
                      Text(
                        '${state.errors} con error · ',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    Text(
                      '$donePct%',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: state.overallProgress,
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: jobs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, i) => _JobTile(
              job: jobs[i],
              onCancel: () => controller.cancelJob(jobs[i].id),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.source,
    required this.destination,
    required this.scanning,
    required this.onPickSource,
    required this.onPickDestination,
  });

  final Folder? source;
  final Folder? destination;
  final bool scanning;
  final VoidCallback onPickSource;
  final VoidCallback onPickDestination;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _FolderRow(
              icon: Icons.usb,
              title: 'Origen (USB / carpeta)',
              value: source?.name,
              buttonLabel: source == null ? 'Elegir' : 'Cambiar',
              onPressed: scanning ? null : onPickSource,
            ),
            const Divider(height: 20),
            _FolderRow(
              icon: Icons.output,
              title: 'Destino',
              value: destination?.name,
              buttonLabel: destination == null ? 'Elegir' : 'Cambiar',
              onPressed: onPickDestination,
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String? value;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: colors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              Text(
                value ?? 'Sin elegir',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: onPressed,
          child: Text(buttonLabel),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.overwrite,
    required this.onProfileChanged,
    required this.onOverwriteChanged,
  });

  final ConversionProfile profile;
  final OverwritePolicy overwrite;
  final ValueChanged<ConversionProfile> onProfileChanged;
  final ValueChanged<OverwritePolicy> onOverwriteChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Perfil de salida',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _segmentOption(
                    context,
                    selected: profile.format == OutputFormat.mp3,
                    label: 'MP3',
                    sub: 'Compatible con todo',
                    onTap: () => onProfileChanged(
                      const ConversionProfile(format: OutputFormat.mp3, bitrate: 192),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _segmentOption(
                    context,
                    selected: profile.format == OutputFormat.m4a,
                    label: 'AAC · M4A',
                    sub: 'Mejor calidad',
                    onTap: () => onProfileChanged(
                      const ConversionProfile(format: OutputFormat.m4a, bitrate: 192),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.drive_file_move_outline, size: 18, color: colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Si el archivo ya existe:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                SegmentedButton<OverwritePolicy>(
                  segments: const [
                    ButtonSegment(
                      value: OverwriteSkip(),
                      label: Text('Saltar'),
                      icon: Icon(Icons.skip_next, size: 16),
                    ),
                    ButtonSegment(
                      value: OverwriteAlways(),
                      label: Text('Reemplazar'),
                      icon: Icon(Icons.refresh, size: 16),
                    ),
                    ButtonSegment(
                      value: OverwriteRename(),
                      label: Text('Renombrar'),
                      icon: Icon(Icons.drive_file_rename_outline, size: 16),
                    ),
                  ],
                  selected: {overwrite},
                  onSelectionChanged: (s) => onOverwriteChanged(s.first),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _segmentOption(
    BuildContext context, {
    required bool selected,
    required String label,
    required String sub,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? colors.primaryContainer : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(color: colors.primary, width: 1.5)
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? colors.primary : colors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  const _JobTile({required this.job, required this.onCancel});

  final ConversionJob job;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final (IconData icon, Color color, String statusText) = switch (job.status) {
      JobStatus.pending => (Icons.schedule, colors.onSurfaceVariant, 'Pendiente'),
      JobStatus.converting => (Icons.hourglass_top, colors.primary, 'Convirtiendo'),
      JobStatus.done => (Icons.check_circle, Colors.green.shade600, 'Listo'),
      JobStatus.error => (Icons.error, colors.error, 'Error'),
      JobStatus.cancelled => (Icons.cancel, colors.error, 'Cancelado'),
      JobStatus.skipped => (Icons.skip_next, colors.onSurfaceVariant, 'Omitido'),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    job.message ?? statusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                        ),
                  ),
                  if (job.status == JobStatus.converting) ...[
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: job.progress.clamp(0.0, 1.0),
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ],
              ),
            ),
            if (job.status == JobStatus.converting ||
                job.status == JobStatus.pending)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onCancel,
              ),
          ],
        ),
      ),
    );
  }
}
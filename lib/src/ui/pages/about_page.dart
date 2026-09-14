import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/theme_controller.dart';
import '../close_app.dart';
import '../themes.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  static const _authorName = 'Edgar Phye Parga';
  static const _authorRole = 'Ingeniero en Desarrollo de Software';
  static const _authorEmail = 'ephye7214@gmail.com';
  static const _createdAt = '13 de septiembre de 2026, 21:01 h';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final currentTheme = ref.watch(themeControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Acerca de',
                style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Personalización, información de la aplicación y su autor.',
                style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Text(
                'Apariencia de la ventana',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Elige entre dos diseños elegantes y modernos.',
                style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 460;
                  final cardWidth = twoColumns
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final t in AppTheme.values)
                        SizedBox(
                          width: cardWidth,
                          child: _ThemeCard(
                            theme: t,
                            selected: t == currentTheme,
                            onTap: () => ref
                                .read(themeControllerProvider.notifier)
                                .setTheme(t),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.music_note, size: 44),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'MusiConvert',
                        style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Conversor y reproductor de audio multiplataforma',
                        textAlign: TextAlign.center,
                        style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 18),
                      const Divider(),
                      const SizedBox(height: 8),
                      _AuthorRow(
                        icon: Icons.person,
                        label: 'Autor',
                        value: _authorName,
                        highlight: true,
                      ),
                      _AuthorRow(
                        icon: Icons.workspace_premium_outlined,
                        label: 'Profesión',
                        value: _authorRole,
                      ),
                      _AuthorRow(
                        icon: Icons.email_outlined,
                        label: 'Correo electrónico',
                        value: _authorEmail,
                      ),
                      _AuthorRow(
                        icon: Icons.event_outlined,
                        label: 'Fecha de creación',
                        value: _createdAt,
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Versión 1.0.0',
                            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: closeApplication,
                icon: const Icon(Icons.power_settings_new),
                label: const Text('Cerrar la aplicación'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatefulWidget {
  const _ThemeCard({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final AppTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final border = widget.selected
        ? Border.all(color: colors.primary, width: 2.5)
        : Border.all(
            color: _hovered ? colors.primary : colors.outlineVariant,
            width: 1.5,
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(18),
          border: border,
          boxShadow: widget.selected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ThemePreview(theme: widget.theme),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(widget.theme.icon, size: 18, color: colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.theme.label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (widget.selected)
                      Icon(Icons.check_circle, size: 20, color: colors.primary),
                  ],
                ),
                Text(
                  widget.theme.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.theme});

  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    final (bgColors, railColor, windowColor, accent, divider) = switch (theme) {
      AppTheme.lavanda => (
          [const Color(0xFFE9E4FB), const Color(0xFFC9BDF2)],
          const Color(0xFFFDFCFF),
          Colors.white,
          const Color(0xFF6750A4),
          const Color(0xFFEAE6F4),
        ),
      AppTheme.onyx => (
          [const Color(0xFF0D0F1E), const Color(0xFF211C3A)],
          const Color(0xFF12142A),
          const Color(0xFF171A2E),
          const Color(0xFF8B7CF6),
          const Color(0xFF272C4C),
        ),
      AppTheme.esmeralda => (
          [const Color(0xFF0B130F), const Color(0xFF123B2A)],
          const Color(0xFF0F1915),
          const Color(0xFF12201A),
          const Color(0xFF2DD4A0),
          const Color(0xFF1F352B),
        ),
      AppTheme.vino => (
          [const Color(0xFF160810), const Color(0xFF3B1D29)],
          const Color(0xFF1D0D15),
          const Color(0xFF241018),
          const Color(0xFFE04D69),
          const Color(0xFF3B1D29),
        ),
    };
    final dark = theme != AppTheme.lavanda;

    return Container(
      height: 92,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bgColors,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 18,
              decoration: BoxDecoration(
                color: railColor,
                borderRadius: BorderRadius.circular(6),
                border: dark ? Border.all(color: divider) : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Icon(Icons.circle, size: 7, color: accent),
                    const Spacer(),
                    Icon(Icons.circle, size: 7,
                        color: dark ? Colors.white24 : const Color(0xFFC8BFE6)),
                    const Spacer(),
                    Icon(Icons.circle, size: 7,
                        color: dark ? Colors.white24 : const Color(0xFFC8BFE6)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: windowColor,
                  borderRadius: BorderRadius.circular(8),
                  border: dark ? Border.all(color: divider) : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: dark
                                    ? Colors.white24
                                    : const Color(0xFFDAD4EE),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: dark
                                  ? Colors.white12
                                  : const Color(0xFFE6E1F4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 5,
                              decoration: BoxDecoration(
                                color: dark
                                    ? Colors.white12
                                    : const Color(0xFFECE8F7),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 16,
                            height: 12,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: highlight ? colors.primaryContainer : colors.surfaceContainerHighest,
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
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
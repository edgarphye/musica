import 'package:flutter/material.dart';

/// Temas de la aplicación: dos diseños de ventana elegantes.
enum AppTheme {
  lavanda,
  onyx,
  esmeralda,
  vino;

  String get label => switch (this) {
        AppTheme.lavanda => 'Lavanda',
        AppTheme.onyx => 'Onyx',
        AppTheme.esmeralda => 'Esmeralda',
        AppTheme.vino => 'Vino',
      };

  String get description => switch (this) {
        AppTheme.lavanda => 'Claro, luminoso y fresco',
        AppTheme.onyx => 'Oscuro, sobrio y sofisticado',
        AppTheme.esmeralda => 'Oscuro, natural y moderno',
        AppTheme.vino => 'Oscuro, intenso y refinado',
      };

  IconData get icon => switch (this) {
        AppTheme.lavanda => Icons.light_mode_outlined,
        AppTheme.onyx => Icons.dark_mode_outlined,
        AppTheme.esmeralda => Icons.eco_outlined,
        AppTheme.vino => Icons.wine_bar,
      };

  ThemeData build() => switch (this) {
        AppTheme.lavanda => _buildLavanda(),
        AppTheme.onyx => _buildOnyx(),
        AppTheme.esmeralda => _buildEsmeralda(),
        AppTheme.vino => _buildVino(),
      };
}

const _seedLavanda = Color(0xFF6750A4);
const _seedOnyx = Color(0xFF8B7CF6);
const _seedEsmeralda = Color(0xFF2DD4A0);
const _seedVino = Color(0xFFE04D69);

ThemeData _buildLavanda() {
  final scheme = ColorScheme.fromSeed(
    seedColor: _seedLavanda,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
scaffoldBackgroundColor: const Color(0xFFF5F3FB),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFEAE6F4), thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _seedLavanda),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: scheme.primary),
      unselectedIconTheme: const IconThemeData(color: Color(0xFF7A728F)),
      selectedLabelTextStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: scheme.primary,
      ),
      unselectedLabelTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF7A728F),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: scheme.primaryContainer,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        );
      }),
    ),
  );
}

ThemeData _buildOnyx() {
  final scheme = ColorScheme.fromSeed(
    seedColor: _seedOnyx,
    brightness: Brightness.dark,
  );
  const cardColor = Color(0xFF171A2E);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFF0D0F1E),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        side: const BorderSide(color: Color(0xFF272C4C)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFF272C4C), thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF272C4C)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF272C4C)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _seedOnyx),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: const Color(0xFF12142A),
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: const IconThemeData(color: Color(0xFFCDBFEA)),
      unselectedIconTheme: const IconThemeData(color: Colors.white54),
      selectedLabelTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFFCDBFEA),
      ),
      unselectedLabelTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white60,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF12142A),
      indicatorColor: scheme.primaryContainer,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        );
      }),
    ),
  );
}

ThemeData _buildEsmeralda() {
  final scheme = ColorScheme.fromSeed(
    seedColor: _seedEsmeralda,
    brightness: Brightness.dark,
  );
  const cardColor = Color(0xFF12201A);
  const borderColor = Color(0xFF1F352B);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFF0B130F),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        side: const BorderSide(color: borderColor),
      ),
    ),
    dividerTheme: DividerThemeData(color: borderColor, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _seedEsmeralda),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: const Color(0xFF0F1915),
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: const IconThemeData(color: Color(0xFF7EE8C8)),
      unselectedIconTheme: const IconThemeData(color: Colors.white54),
      selectedLabelTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF7EE8C8),
      ),
      unselectedLabelTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white60,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF0F1915),
      indicatorColor: scheme.primaryContainer,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        );
      }),
    ),
  );
}

ThemeData _buildVino() {
  final scheme = ColorScheme.fromSeed(
    seedColor: _seedVino,
    brightness: Brightness.dark,
  );
  const cardColor = Color(0xFF241018);
  const borderColor = Color(0xFF3B1D29);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFF160810),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        side: const BorderSide(color: borderColor),
      ),
    ),
    dividerTheme: DividerThemeData(color: borderColor, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _seedVino),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: const Color(0xFF1D0D15),
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: const IconThemeData(color: Color(0xFFF5A8B9)),
      unselectedIconTheme: const IconThemeData(color: Colors.white54),
      selectedLabelTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFFF5A8B9),
      ),
      unselectedLabelTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white60,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF1D0D15),
      indicatorColor: scheme.primaryContainer,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        );
      }),
    ),
  );
}
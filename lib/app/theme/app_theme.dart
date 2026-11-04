import 'package:flutter/material.dart';

import 'palette.dart';
import 'techno_colors.dart';

const fontTitle = 'ChakraPetch';
const fontBody = 'AtkinsonHyperlegible';
const fontCode = 'IBMPlexMono';

/// Coins biseautés, signature visuelle des composants.
const bevel = BorderRadius.only(
  topRight: Radius.circular(14),
  bottomLeft: Radius.circular(14),
);

extension TechnoContext on BuildContext {
  TechnoColors get techno => Theme.of(this).extension<TechnoColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
}

abstract final class AppTheme {
  static final dark = _build(
    ColorScheme.fromSeed(
      seedColor: Palette.emeraude,
      brightness: Brightness.dark,
      primary: Palette.emeraude,
      onPrimary: Palette.fondSombre,
      secondary: TechnoColors.dark.violet,
      onSecondary: Palette.fondSombre,
      tertiary: Palette.orange,
      onTertiary: Palette.fondSombre,
      surface: Palette.bleuNuit,
      onSurface: const Color(0xFFEDF0FA),
      onSurfaceVariant: TechnoColors.dark.muted,
      outline: TechnoColors.dark.border,
      outlineVariant: TechnoColors.dark.border,
      error: TechnoColors.dark.danger,
      onError: Palette.fondSombre,
      surfaceContainer: const Color(0xFF151C33),
      surfaceContainerHigh: const Color(0xFF1A2240),
    ),
    TechnoColors.dark,
    Palette.fondSombre,
  );

  static final light = _build(
    ColorScheme.fromSeed(
      seedColor: Palette.emeraude,
      primary: TechnoColors.light.emeraude,
      onPrimary: Colors.white,
      secondary: TechnoColors.light.violet,
      onSecondary: Colors.white,
      tertiary: TechnoColors.light.orange,
      onTertiary: Colors.white,
      surface: Colors.white,
      onSurface: const Color(0xFF141A2E),
      onSurfaceVariant: TechnoColors.light.muted,
      outline: const Color(0xFF7A7F9E),
      outlineVariant: TechnoColors.light.border,
      error: TechnoColors.light.danger,
      onError: Colors.white,
      surfaceContainer: const Color(0xFFF1EEFC),
      surfaceContainerHigh: const Color(0xFFE9E5FA),
    ),
    TechnoColors.light,
    const Color(0xFFF7F5FF),
  );

  static TextTheme _textTheme(Color color) {
    TextStyle title(double size, FontWeight weight) => TextStyle(
      fontFamily: fontTitle,
      fontSize: size,
      fontWeight: weight,
      height: 1.2,
    );
    TextStyle body(double size, FontWeight weight, double height) => TextStyle(
      fontFamily: fontBody,
      fontSize: size,
      fontWeight: weight,
      height: height,
    );

    return TextTheme(
      displaySmall: title(34, FontWeight.w700),
      headlineMedium: title(28, FontWeight.w700),
      headlineSmall: title(24, FontWeight.w700),
      titleLarge: title(21, FontWeight.w600),
      titleMedium: title(18, FontWeight.w600),
      titleSmall: title(16, FontWeight.w600),
      bodyLarge: body(17, FontWeight.w400, 1.5),
      bodyMedium: body(15, FontWeight.w400, 1.45),
      bodySmall: body(13, FontWeight.w400, 1.4),
      labelLarge: body(15, FontWeight.w700, 1.2),
      labelMedium: body(13, FontWeight.w700, 1.2),
      labelSmall: body(12, FontWeight.w700, 1.2),
    ).apply(bodyColor: color, displayColor: color);
  }

  static ThemeData _build(
    ColorScheme scheme,
    TechnoColors techno,
    Color background,
  ) {
    final text = _textTheme(scheme.onSurface);

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: fontBody,
      textTheme: text,
      extensions: [techno],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: techno.emeraude.withValues(alpha: 0.2),
        indicatorShape: const BeveledRectangleBorder(borderRadius: bevel),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? techno.emeraude
                : techno.muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium!.copyWith(
            color: states.contains(WidgetState.selected)
                ? techno.emeraude
                : techno.muted,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: techno.emeraude.withValues(alpha: 0.2),
        indicatorShape: const BeveledRectangleBorder(borderRadius: bevel),
        selectedIconTheme: IconThemeData(color: techno.emeraude),
        unselectedIconTheme: IconThemeData(color: techno.muted),
        selectedLabelTextStyle: text.labelMedium!.copyWith(
          color: techno.emeraude,
        ),
        unselectedLabelTextStyle: text.labelMedium!.copyWith(
          color: techno.muted,
        ),
      ),
      dividerTheme: DividerThemeData(color: techno.border, space: 1),
      iconTheme: IconThemeData(color: scheme.onSurface),
      listTileTheme: ListTileThemeData(
        iconColor: techno.emeraude,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall!.copyWith(color: techno.muted),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(
            BeveledRectangleBorder(borderRadius: bevel),
          ),
          textStyle: WidgetStatePropertyAll(text.labelMedium),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surfaceContainerHigh,
        contentTextStyle: text.bodyMedium,
        shape: BeveledRectangleBorder(
          borderRadius: bevel,
          side: BorderSide(color: techno.border),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// «Clinic OS» theme — explicit token-driven [ColorScheme] (no fromSeed) so the
/// whole app matches the prototype: light canvas #ECF1EF, teal accent #0F9D8F,
/// cards radius 18, Manrope/Golos type. The dark-teal sidebar is painted by the
/// shell directly (always dark), so the app itself is a single light design —
/// `light()` and `dark()` return the same theme. `themeModeProvider` stays
/// wired (app.dart / app_shell) so re-introducing a real dark mode later is a
/// one-file change here.
class KozTheme {
  static ThemeData light() => _build();
  static ThemeData dark() => _build();

  static const ColorScheme _scheme = ColorScheme.light(
    primary: AppColors.accent,
    onPrimary: Colors.white,
    primaryContainer: AppColors.tealBg,
    onPrimaryContainer: AppColors.tealDark,
    secondary: AppColors.mint,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.tealBg,
    onSecondaryContainer: AppColors.tealDark,
    surface: AppColors.card,
    onSurface: AppColors.ink,
    surfaceContainerHighest: AppColors.line2,
    surfaceContainerHigh: AppColors.line2,
    onSurfaceVariant: AppColors.sub,
    outline: AppColors.muted,
    outlineVariant: AppColors.line,
    error: AppColors.red,
    onError: Colors.white,
    errorContainer: AppColors.redBg,
    onErrorContainer: AppColors.red,
  );

  static ThemeData _build() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _scheme,
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: AppTypography.textTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
            fontFamily: 'Manrope',
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 19),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.rCard),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      dividerTheme: const DividerThemeData(
          color: AppColors.line, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        isDense: true,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.rField),
            borderSide: const BorderSide(color: AppColors.line)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.rField),
            borderSide: const BorderSide(color: AppColors.line)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.rField),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.6)),
      ),
      chipTheme: const ChipThemeData(
        shape: StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: AppColors.tealBg,
        selectedColor: AppColors.accent,
        labelStyle: TextStyle(color: AppColors.tealDark, fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // Height-only minimum. `Size.fromHeight` sets width=infinity, which
          // throws "BoxConstraints forces an infinite width" for any button
          // placed in a Row (loose width). Full-width buttons get their width
          // from a tight parent (stretch Column / SizedBox), not from here.
          minimumSize: const Size(0, 48),
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.rField)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          // Height-only minimum (see filledButtonTheme above): avoid infinite
          // width when an outlined button sits in a Row.
          minimumSize: const Size(0, 46),
          foregroundColor: AppColors.sub,
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.rField)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.tealDark),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.sidebarTop,
        contentTextStyle: TextStyle(color: AppColors.onDark),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

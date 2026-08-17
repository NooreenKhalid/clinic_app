import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared visual tokens for Smart Clinic. Screen widgets should obtain surface
/// and text colors from [Theme.of] so both brightness modes remain readable.
class AppTheme {
  static const background = Color(0xFF0B1017);
  static const surface = Color(0xFF131B26);
  static const surfaceElevated = Color(0xFF1A2532);
  static const outline = Color(0xFF2A3747);
  static const primary = Color(0xFF54B8E8);
  static const success = Color(0xFF54B889);
  static const warning = Color(0xFFE6AE58);
  static const danger = Color(0xFFDC7377);

  static const _darkScheme = ColorScheme.dark(
    primary: primary,
    onPrimary: Color(0xFF06131A),
    secondary: Color(0xFF7BD4F5),
    onSecondary: Color(0xFF06131A),
    surface: surface,
    onSurface: Color(0xFFF2F6FA),
    onSurfaceVariant: Color(0xFFBBC8D7),
    error: danger,
    onError: Color(0xFF26080B),
    outline: outline,
    outlineVariant: Color(0xFF22303E),
  );

  static const _lightScheme = ColorScheme.light(
    primary: Color(0xFF1687B8),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF1687B8),
    onSecondary: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF17212B),
    onSurfaceVariant: Color(0xFF526170),
    error: Color(0xFFC94F55),
    onError: Color(0xFFFFFFFF),
    outline: Color(0xFFB9C4CD),
    outlineVariant: Color(0xFFE0E6EB),
  );

  static final darkTheme = _buildTheme(
    scheme: _darkScheme,
    scaffold: background,
    inputFill: surfaceElevated,
  );

  static final lightTheme = _buildTheme(
    scheme: _lightScheme,
    scaffold: const Color(0xFFF6F8FA),
    inputFill: const Color(0xFFFFFFFF),
  );

  static ThemeData _buildTheme({
    required ColorScheme scheme,
    required Color scaffold,
    required Color inputFill,
  }) {
    final textTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: scheme.outline),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scaffold,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: scheme.primary),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        helperStyle: TextStyle(color: scheme.onSurfaceVariant),
        errorStyle: TextStyle(color: scheme.error),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withOpacity(.12),
          disabledForegroundColor: scheme.onSurface.withOpacity(.38),
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.brightness == Brightness.dark
            ? surfaceElevated
            : const Color(0xFF26323D),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

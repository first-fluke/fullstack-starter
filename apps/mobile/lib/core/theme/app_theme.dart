import 'package:flutter/material.dart';
import 'package:mobile/core/theme/generated_theme.dart';

/// {@template app_theme}
/// The theme configuration for the application.
///
/// Uses the primary color from [generatedLightTheme] / [generatedDarkTheme]
/// as the Material [ColorScheme] seed so the Material and Forui layers stay
/// visually consistent.
/// {@endtemplate}
class AppTheme {
  AppTheme._();

  /// The primary color from the generated light theme token set.
  static Color get _primaryColor => generatedLightTheme.colors.primary;

  /// The light theme.
  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _primaryColor),
  );

  /// The dark theme.
  static ThemeData get dark => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
    ),
  );
}

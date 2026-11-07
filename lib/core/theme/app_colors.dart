import 'package:flutter/material.dart';

/// Maryam brand palette: deep plum night + glowing candy pink.
class AppColors {
  AppColors._();

  // ── Base ──
  static const background = Color(0xFF12060F);
  static const backgroundTop = Color(0xFF2A0B22);
  static const surface = Color(0xFF1E0A19);
  static const surfaceLight = Color(0xFF2C1226);

  // ── Brand ──
  static const primary = Color(0xFFF0368E);
  static const primaryLight = Color(0xFFFF7DB8);
  static const primaryDeep = Color(0xFFB0125F);
  static const violet = Color(0xFF9B3BE0);

  /// Same as [primaryLight] (kept so older code still compiles).
  static const secondary = primaryLight;
  static const danger = Color(0xFFFF4D67);

  // ── Text ──
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFC6A7BB);
  static const textTertiary = Color(0xFF8C6C82);

  // ── Glass surfaces ──
  static const glass = Color(0x14FFFFFF); // 8% white
  static const glassStrong = Color(0x24FFFFFF); // 14% white
  static const glassBorder = Color(0x1AFFFFFF); // 10% white

  static const accentGradient = LinearGradient(
    colors: [primaryLight, primary, primaryDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const titleGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFFFC4DF), primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const backgroundGradient = LinearGradient(
    colors: [backgroundTop, background, background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, 0.55, 1],
  );

  static const dangerGradient = LinearGradient(
    colors: [Color(0xFFFF7A8E), danger, Color(0xFFC81E45)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Soft colored glow under buttons and cards.
  static List<BoxShadow> glow(Color color, {double strength = 1}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.45 * strength),
          blurRadius: 24 * strength,
          offset: Offset(0, 8 * strength),
        ),
      ];

  /// Placeholder gradients for songs without artwork (all in the brand family).
  static const placeholderGradients = [
    [Color(0xFFFF7DB8), Color(0xFFC2185B)],
    [Color(0xFFB45CFF), Color(0xFF6A1B9A)],
    [Color(0xFFFF9A8B), Color(0xFFE0457B)],
    [Color(0xFFF06292), Color(0xFF7B1FA2)],
    [Color(0xFFFFB199), Color(0xFFFF0844)],
    [Color(0xFF8E7CFF), Color(0xFFE040FB)],
  ];

  static List<Color> gradientFor(String seed) =>
      placeholderGradients[seed.hashCode.abs() % placeholderGradients.length];
}

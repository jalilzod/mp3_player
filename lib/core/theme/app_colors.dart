import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFF0B0B12);
  static const surface = Color(0xFF16161F);
  static const surfaceLight = Color(0xFF22222E);

  static const primary = Color(0xFF8B5CF6); // violet
  static const secondary = Color(0xFFFF4D8D); // pink
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF9A9AB0);

  static const accentGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const backgroundGradient = LinearGradient(
    colors: [Color(0xFF1A1030), background, background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, 0.45, 1],
  );

  /// Pleasant placeholder gradients for songs without artwork.
  static const placeholderGradients = [
    [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
    [Color(0xFF10B981), Color(0xFF14B8A6)],
    [Color(0xFF6366F1), Color(0xFFA855F7)],
    [Color(0xFFF43F5E), Color(0xFFFB923C)],
  ];

  static List<Color> gradientFor(String seed) =>
      placeholderGradients[seed.hashCode.abs() % placeholderGradients.length];
}

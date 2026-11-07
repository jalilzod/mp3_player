import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Deep plum background with slowly drifting pink / violet light orbs.
/// Cheap to draw (three radial gradients), repaints only itself.
class AuroraBackground extends StatefulWidget {
  /// 0 = calm, 1 = normal, >1 = stronger glow (player screen).
  final double intensity;

  const AuroraBackground({super.key, this.intensity = 1});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        ),
        RepaintBoundary(
          child: CustomPaint(
            painter: _AuroraPainter(_c, widget.intensity),
          ),
        ),
      ],
    );
  }
}

class _Orb {
  final Color color;
  final double x, y, radius, phase, opacity;
  const _Orb(this.color, this.x, this.y, this.radius, this.phase, this.opacity);
}

class _AuroraPainter extends CustomPainter {
  final Animation<double> animation;
  final double intensity;

  _AuroraPainter(this.animation, this.intensity) : super(repaint: animation);

  static const _orbs = [
    _Orb(AppColors.primary, 0.12, 0.06, 0.85, 0.0, 0.38),
    _Orb(AppColors.violet, 0.92, 0.22, 0.75, 2.1, 0.26),
    _Orb(AppColors.primaryLight, 0.55, 0.55, 0.65, 4.2, 0.12),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value * 2 * math.pi;
    for (final orb in _orbs) {
      // Integer multipliers of t keep the loop seamless.
      final center = Offset(
        (orb.x + 0.10 * math.sin(t + orb.phase)) * size.width,
        (orb.y + 0.05 * math.cos(2 * t + orb.phase)) * size.height,
      );
      final radius = orb.radius * size.width;
      final alpha = (orb.opacity * intensity).clamp(0.0, 0.8);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            orb.color.withValues(alpha: alpha),
            orb.color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => old.intensity != intensity;
}

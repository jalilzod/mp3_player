import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'glass.dart';

/// Friendly empty / info screen with a gently floating glowing icon.
class EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;
  final Widget? secondary;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.actionIcon = Icons.add_rounded,
    this.onAction,
    this.secondary,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _float,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, -10 * Curves.easeInOut.transform(_float.value)),
                child: child,
              ),
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.08),
                  border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.15)),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.accentGradient,
                    boxShadow: AppColors.glow(AppColors.primary, strength: 1.2),
                  ),
                  child: Icon(widget.icon, size: 44, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14.5, height: 1.4),
            ),
            if (widget.actionLabel != null && widget.onAction != null) ...[
              const SizedBox(height: 26),
              PillButton(
                icon: widget.actionIcon,
                label: widget.actionLabel!,
                onTap: widget.onAction!,
              ),
            ],
            if (widget.secondary != null) ...[
              const SizedBox(height: 8),
              widget.secondary!,
            ],
          ],
        ),
      ),
    );
  }
}

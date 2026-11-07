import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import 'pressable.dart';

/// Round frosted button (or a glowing pink one when [filled]).
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final bool filled;
  final Color? iconColor;
  final Widget? child;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.size = 44,
    this.filled = false,
    this.iconColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: filled ? AppColors.accentGradient : null,
        color: filled ? null : AppColors.glass,
        border: filled ? null : Border.all(color: AppColors.glassBorder),
        boxShadow: filled ? AppColors.glow(AppColors.primary, strength: 0.6) : null,
      ),
      alignment: Alignment.center,
      child: child ?? Icon(icon, size: size * 0.48, color: iconColor ?? Colors.white),
    );
    final pressable = Pressable(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: button,
    );
    return tooltip == null ? pressable : Tooltip(message: tooltip!, child: pressable);
  }
}

/// Pill button with icon + label. Pink gradient, or frosted glass when [glass].
class PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool glass;
  final bool active;

  const PillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.glass = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = glass && !active ? Colors.white.withValues(alpha: 0.85) : Colors.white;
    return Pressable(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: glass
              ? (active
                  ? LinearGradient(colors: [
                      AppColors.primary.withValues(alpha: 0.35),
                      AppColors.primaryDeep.withValues(alpha: 0.2),
                    ])
                  : null)
              : AppColors.accentGradient,
          color: glass && !active ? AppColors.glass : null,
          border: glass
              ? Border.all(
                  color: active
                      ? AppColors.primaryLight.withValues(alpha: 0.6)
                      : AppColors.glassBorder)
              : null,
          boxShadow: glass ? null : AppColors.glow(AppColors.primary, strength: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Title at the top of every bottom sheet.
class SheetTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const SheetTitle(this.title, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Column(
        children: [
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.primaryLight, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

/// A row inside a bottom sheet: icon bubble, label, optional check / subtitle.
class SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  const SheetOption({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.selected = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = danger ? AppColors.danger : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? accent.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: accent.withValues(alpha: 0.15),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: selected && !danger ? AppColors.accentGradient : null,
                    color: selected && !danger
                        ? null
                        : (danger
                            ? AppColors.danger.withValues(alpha: 0.14)
                            : AppColors.glass),
                  ),
                  child: Icon(icon,
                      size: 20,
                      color: danger
                          ? AppColors.danger
                          : (selected ? Colors.white : AppColors.textSecondary)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: danger ? AppColors.danger : Colors.white,
                          )),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(subtitle!,
                              style: const TextStyle(
                                  fontSize: 12.5, color: AppColors.textTertiary)),
                        ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                  child: selected
                      ? const Icon(Icons.check_circle_rounded,
                          key: ValueKey('on'), color: AppColors.primaryLight)
                      : const SizedBox(key: ValueKey('off'), width: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

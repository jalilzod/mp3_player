import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// Heart that pops with an elastic bounce and a soft pink glow.
class FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  final double size;

  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onTap,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.elasticOut,
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: DecoratedBox(
          key: ValueKey(isFavorite),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: isFavorite
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      blurRadius: size * 0.7,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: size,
            color: isFavorite ? AppColors.primary : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

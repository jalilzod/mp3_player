import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../domain/entities/song.dart';
import '../utils/song_display.dart';
import 'equalizer_bars.dart';
import 'favorite_button.dart';
import 'song_artwork.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final bool isCurrent;
  final bool isPlaying;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onMore;

  const SongTile({
    super.key,
    required this.song,
    required this.isCurrent,
    required this.isPlaying,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final artist = song.artistText(context.s);
    final subtitle = song.duration > Duration.zero
        ? '$artist  ·  ${song.duration.toClock()}'
        : artist;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isCurrent
              ? [
                  AppColors.primary.withValues(alpha: 0.24),
                  AppColors.primaryDeep.withValues(alpha: 0.06),
                ]
              : [Colors.transparent, Colors.transparent],
        ),
        border: Border.all(
          color: isCurrent
              ? AppColors.primaryLight.withValues(alpha: 0.35)
              : Colors.transparent,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          splashColor: AppColors.primary.withValues(alpha: 0.14),
          highlightColor: Colors.white.withValues(alpha: 0.03),
          onTap: onTap,
          onLongPress: onMore,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 0, 8),
            child: Row(
              children: [
                _Artwork(song: song, isCurrent: isCurrent, isPlaying: isPlaying),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                          color: isCurrent ? AppColors.primaryLight : Colors.white,
                          letterSpacing: -0.1,
                        ),
                        child: Text(song.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                FavoriteButton(isFavorite: isFavorite, onTap: onFavorite, size: 22),
                IconButton(
                  tooltip: context.s.more,
                  visualDensity: VisualDensity.compact,
                  onPressed: onMore,
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppColors.textTertiary, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  final Song song;
  final bool isCurrent;
  final bool isPlaying;
  const _Artwork({required this.song, required this.isCurrent, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isCurrent
            ? AppColors.glow(AppColors.primary, strength: 0.55)
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SongArtwork(song: song, size: 54, radius: 16),
          AnimatedOpacity(
            opacity: isCurrent ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: isCurrent
                  ? EqualizerBars(animating: isPlaying, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/song.dart';
import '../cubit/library/library_cubit.dart';
import '../utils/song_actions.dart';
import '../utils/song_display.dart';
import 'glass.dart';
import 'song_artwork.dart';

/// "⋮" menu for a song: play, favorite, delete.
class SongActionsSheet {
  SongActionsSheet._();

  static void show(BuildContext context, Song song, {VoidCallback? onPlay}) {
    final library = context.read<LibraryCubit>();
    final s = context.s;
    final isFavorite = library.state.isFavorite(song.id);
    final play = onPlay;

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Song header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.glow(AppColors.primary, strength: 0.5),
                      ),
                      child: SongArtwork(song: song, size: 60, radius: 16),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(song.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(song.artistText(s),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                color: AppColors.glassBorder,
              ),
              if (play != null)
                SheetOption(
                  icon: Icons.play_arrow_rounded,
                  label: s.play,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    play();
                  },
                ),
              SheetOption(
                icon: isFavorite
                    ? Icons.heart_broken_rounded
                    : Icons.favorite_border_rounded,
                label: isFavorite ? s.removeFromFavorites : s.addToFavorites,
                onTap: () {
                  Navigator.pop(sheetContext);
                  library.toggleFavorite(song);
                },
              ),
              SheetOption(
                icon: Icons.delete_outline_rounded,
                label: s.delete,
                subtitle: s.swipeHint,
                danger: true,
                onTap: () {
                  Navigator.pop(sheetContext);
                  SongActions.delete(context, song);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

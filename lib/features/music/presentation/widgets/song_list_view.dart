import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/song.dart';
import '../cubit/library/library_cubit.dart';
import '../cubit/library/library_state.dart';
import '../cubit/player/player_cubit.dart';
import '../cubit/player/player_state.dart';
import '../utils/song_actions.dart';
import 'empty_state.dart';
import 'glass.dart';
import 'song_actions_sheet.dart';
import 'song_tile.dart';

class SongListView extends StatelessWidget {
  final List<Song> songs;
  final LibraryState library;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  /// Show an "Import songs" button on the empty screen.
  final bool showImportOnEmpty;

  const SongListView({
    super.key,
    required this.songs,
    required this.library,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.showImportOnEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    final libraryCubit = context.read<LibraryCubit>();
    final playerCubit = context.read<PlayerCubit>();

    if (songs.isEmpty) {
      return RefreshIndicator(
        onRefresh: libraryCubit.refresh,
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceLight,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 160),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.07),
            EmptyState(
              icon: emptyIcon,
              title: emptyTitle,
              subtitle: emptySubtitle,
              actionLabel: showImportOnEmpty ? context.s.importSongs : null,
              onAction: showImportOnEmpty ? libraryCubit.importMusic : null,
            ),
          ],
        ),
      );
    }

    return BlocBuilder<PlayerCubit, PlayerViewState>(
      buildWhen: (a, b) =>
          a.currentSong != b.currentSong || a.isPlaying != b.isPlaying,
      builder: (context, player) {
        return RefreshIndicator(
          onRefresh: libraryCubit.refresh,
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceLight,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.only(top: 2, bottom: 160),
            itemCount: songs.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return _ListHeader(
                  count: songs.length,
                  onPlayAll: () => playerCubit.playSongs(songs),
                  onShuffle: () => playerCubit.shuffleAll(songs),
                );
              }
              final index = i - 1;
              final song = songs[index];
              return _FadeSlideIn(
                key: ValueKey('row_${song.id}'),
                index: i,
                child: Dismissible(
                  key: ValueKey('dismiss_${song.id}'),
                  direction: DismissDirection.endToStart,
                  dismissThresholds: const {DismissDirection.endToStart: 0.35},
                  background: const _DeleteBackground(),
                  onDismissed: (_) => SongActions.delete(context, song),
                  child: SongTile(
                    song: song,
                    isCurrent: player.currentSong?.id == song.id,
                    isPlaying: player.isPlaying,
                    isFavorite: library.isFavorite(song.id),
                    onTap: () => playerCubit.playSongs(songs, index: index),
                    onFavorite: () => libraryCubit.toggleFavorite(song),
                    onMore: () => SongActionsSheet.show(
                      context,
                      song,
                      onPlay: () => playerCubit.playSongs(songs, index: index),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Red "Delete" layer revealed when swiping a song to the left.
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: AppColors.dangerGradient,
      ),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.s.delete,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ],
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  final int count;
  final VoidCallback onPlayAll;
  final VoidCallback onShuffle;

  const _ListHeader({
    required this.count,
    required this.onPlayAll,
    required this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.centerLeft,
                children: [...previous, if (current != null) current],
              ),
              child: Text(
                s.songsCount(count),
                key: ValueKey(count),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          GlassIconButton(
            icon: Icons.shuffle_rounded,
            tooltip: s.shuffle,
            size: 40,
            onTap: onShuffle,
          ),
          const SizedBox(width: 10),
          PillButton(
            icon: Icons.play_arrow_rounded,
            label: s.playAll,
            onTap: onPlayAll,
          ),
        ],
      ),
    );
  }
}

/// Staggered entrance animation for list items.
class _FadeSlideIn extends StatelessWidget {
  final int index;
  final Widget child;
  const _FadeSlideIn({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final delay = index.clamp(0, 12) * 35;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + delay),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

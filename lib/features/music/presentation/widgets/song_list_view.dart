import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/song.dart';
import '../cubit/library/library_cubit.dart';
import '../cubit/library/library_state.dart';
import '../cubit/player/player_cubit.dart';
import '../cubit/player/player_state.dart';
import 'song_tile.dart';

class SongListView extends StatelessWidget {
  final List<Song> songs;
  final LibraryState library;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  const SongListView({
    super.key,
    required this.songs,
    required this.library,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final libraryCubit = context.read<LibraryCubit>();
    final playerCubit = context.read<PlayerCubit>();

    if (songs.isEmpty) {
      return RefreshIndicator(
        onRefresh: libraryCubit.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
            Icon(emptyIcon, size: 72, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(emptyTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(emptySubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
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
          color: AppColors.secondary,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: songs.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return _ListHeader(
                  count: songs.length,
                  onPlayAll: () => playerCubit.playSongs(songs),
                  onShuffle: () => playerCubit.shuffleAll(songs),
                );
              }
              final song = songs[i - 1];
              return _FadeSlideIn(
                index: i,
                child: SongTile(
                  song: song,
                  isCurrent: player.currentSong?.id == song.id,
                  isPlaying: player.isPlaying,
                  isFavorite: library.isFavorite(song.id),
                  onTap: () => playerCubit.playSongs(songs, index: i - 1),
                  onFavorite: () => libraryCubit.toggleFavorite(song),
                ),
              );
            },
          ),
        );
      },
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
      child: Row(
        children: [
          Text('$count songs',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const Spacer(),
          TextButton.icon(
            onPressed: onShuffle,
            icon: const Icon(Icons.shuffle_rounded, size: 18),
            label: const Text('Shuffle'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
          const SizedBox(width: 4),
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: onPlayAll,
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
            ),
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
  const _FadeSlideIn({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final delay = (index.clamp(0, 12)) * 30;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + delay),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

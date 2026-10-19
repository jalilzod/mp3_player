import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../cubit/library/library_cubit.dart';
import '../cubit/library/library_state.dart';
import '../cubit/player/player_cubit.dart';
import '../cubit/player/player_state.dart';
import '../widgets/favorite_button.dart';
import '../widgets/player_controls.dart';
import '../widgets/player_sheets.dart';
import '../widgets/seek_bar.dart';
import '../widgets/song_artwork.dart';
import '../widgets/vinyl_artwork.dart';

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  /// Slide-up transition from the mini player.
  static void open(BuildContext context) {
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => const PlayerPage(),
      transitionsBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(
            parent: anim, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
          child: child,
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlayerCubit>();

    return BlocBuilder<PlayerCubit, PlayerViewState>(
      builder: (context, state) {
        final song = state.currentSong;
        if (song == null) {
          return const Scaffold(body: Center(child: Text('Nothing playing')));
        }

        return GestureDetector(
          // Swipe down to close
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) > 300) Navigator.pop(context);
          },
          // Swipe left / right to change song
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v < -400) cubit.next();
            if (v > 400) cubit.previous();
          },
          child: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Blurred artwork background that cross-fades on song change.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 700),
                  child: SizedBox.expand(
                    key: ValueKey(song.id),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SongArtwork(song: song, size: 300, radius: 0),
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        AppColors.background.withValues(alpha: 0.85),
                        AppColors.background,
                      ],
                      stops: const [0, 0.55, 1],
                    ),
                  ),
                ),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final artSize = math.min(c.maxWidth * 0.78, c.maxHeight * 0.42);
                      return Column(
                        children: [
                          _TopBar(state: state),
                          const Spacer(),
                          VinylArtwork(
                              song: song, isPlaying: state.isPlaying, size: artSize),
                          const Spacer(),
                          _TitleRow(state: state),
                          const SizedBox(height: 12),
                          SeekBar(stream: cubit.positionStream, onSeek: cubit.seek),
                          const SizedBox(height: 12),
                          PlayerControls(state: state, cubit: cubit),
                          const SizedBox(height: 20),
                          _BottomBar(state: state),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final PlayerViewState state;
  const _TopBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          ),
          Expanded(
            child: Column(
              children: [
                const Text('NOW PLAYING',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(state.currentSong?.album ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => PlayerSheets.showQueue(context),
            icon: const Icon(Icons.queue_music_rounded),
          ),
        ],
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  final PlayerViewState state;
  const _TitleRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final song = state.currentSong!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0.15, 0), end: Offset.zero)
                      .animate(anim),
                  child: child,
                ),
              ),
              child: Column(
                key: ValueKey(song.id),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text(song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          BlocBuilder<LibraryCubit, LibraryState>(
            buildWhen: (a, b) => a.favoriteIds != b.favoriteIds,
            builder: (context, lib) => FavoriteButton(
              isFavorite: lib.isFavorite(song.id),
              size: 30,
              onTap: () => context.read<LibraryCubit>().toggleFavorite(song),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final PlayerViewState state;
  const _BottomBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Pill(
          icon: Icons.speed_rounded,
          label: '${state.speed}x',
          active: state.speed != 1.0,
          onTap: () => PlayerSheets.showSpeed(context),
        ),
        _Pill(
          icon: Icons.bedtime_outlined,
          label: state.sleepAt == null
              ? 'Sleep'
              : '${state.sleepAt!.difference(DateTime.now()).inMinutes + 1}m',
          active: state.sleepAt != null,
          onTap: () => PlayerSheets.showSleepTimer(context),
        ),
        _Pill(
          icon: Icons.playlist_play_rounded,
          label: 'Queue',
          active: false,
          onTap: () => PlayerSheets.showQueue(context),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Pill({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? AppColors.secondary.withValues(alpha: 0.18)
          : Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: active ? AppColors.secondary : Colors.white70),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? AppColors.secondary : Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

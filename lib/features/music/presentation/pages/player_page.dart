import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/song.dart';
import '../cubit/library/library_cubit.dart';
import '../cubit/library/library_state.dart';
import '../cubit/player/player_cubit.dart';
import '../cubit/player/player_state.dart';
import '../utils/song_display.dart';
import '../widgets/aurora_background.dart';
import '../widgets/favorite_button.dart';
import '../widgets/glass.dart';
import '../widgets/player_controls.dart';
import '../widgets/player_sheets.dart';
import '../widgets/seek_bar.dart';
import '../widgets/song_actions_sheet.dart';
import '../widgets/song_artwork.dart';
import '../widgets/vinyl_artwork.dart';

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  /// Slides up from the mini player, with the artwork flying in (Hero).
  static void open(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 520),
      reverseTransitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => const PlayerPage(),
      transitionsBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutQuart,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
          child: FadeTransition(
            opacity: Tween(begin: 0.4, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlayerCubit>();

    return BlocConsumer<PlayerCubit, PlayerViewState>(
      // The playing song was deleted and nothing is left → close the player.
      listenWhen: (a, b) => a.currentSong != null && b.currentSong == null,
      listener: (context, _) => Navigator.of(context).maybePop(),
      builder: (context, state) {
        final song = state.currentSong;
        if (song == null) {
          return const Scaffold(backgroundColor: AppColors.background);
        }

        return GestureDetector(
          // Swipe down to close
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) > 300) Navigator.pop(context);
          },
          // Swipe left / right to change song
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v < -400) {
              HapticFeedback.selectionClick();
              cubit.next();
            } else if (v > 400) {
              HapticFeedback.selectionClick();
              cubit.previous();
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: Stack(
              fit: StackFit.expand,
              children: [
                const AuroraBackground(intensity: 1.3),
                _ArtworkBackdrop(song: song),
                const _Shade(),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final artSize = math.min(c.maxWidth * 0.76, c.maxHeight * 0.4);
                      return Column(
                        children: [
                          _TopBar(state: state),
                          const Spacer(),
                          VinylArtwork(
                              song: song, isPlaying: state.isPlaying, size: artSize),
                          const Spacer(),
                          _TitleRow(state: state),
                          const SizedBox(height: 14),
                          SeekBar(stream: cubit.positionStream, onSeek: cubit.seek),
                          const SizedBox(height: 4),
                          PlayerControls(state: state, cubit: cubit),
                          const SizedBox(height: 16),
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

/// Heavily blurred artwork behind everything; cross-fades on song change.
class _ArtworkBackdrop extends StatelessWidget {
  final Song song;
  const _ArtworkBackdrop({required this.song});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 900),
      child: Opacity(
        key: ValueKey(song.id),
        opacity: 0.55,
        child: SizedBox.expand(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: FittedBox(
              fit: BoxFit.cover,
              child: SongArtwork(song: song, size: 300, radius: 0),
            ),
          ),
        ),
      ),
    );
  }
}

/// Darkens the bottom so text and controls stay readable.
class _Shade extends StatelessWidget {
  const _Shade();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withValues(alpha: 0.25),
            AppColors.background.withValues(alpha: 0.55),
            AppColors.background.withValues(alpha: 0.92),
          ],
          stops: const [0, 0.5, 1],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final PlayerViewState state;
  const _TopBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final song = state.currentSong!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.keyboard_arrow_down_rounded,
            onTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  context.s.nowPlaying,
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 2.4,
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    song.albumText(context.s),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          GlassIconButton(
            icon: Icons.more_horiz_rounded,
            tooltip: context.s.more,
            onTap: () => SongActionsSheet.show(context, song),
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
              duration: const Duration(milliseconds: 450),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0.12, 0), end: Offset.zero)
                      .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              ),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.centerLeft,
                children: [...previous, if (current != null) current],
              ),
              child: Column(
                key: ValueKey(song.id),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(song.artistText(context.s),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500)),
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
    final s = context.s;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          PillButton(
            icon: Icons.speed_rounded,
            label: '${state.speed}x',
            glass: true,
            active: state.speed != 1.0,
            onTap: () => PlayerSheets.showSpeed(context),
          ),
          PillButton(
            icon: Icons.bedtime_outlined,
            label: state.sleepAt == null
                ? s.sleep
                : s.minutesShort(state.sleepAt!.difference(DateTime.now()).inMinutes + 1),
            glass: true,
            active: state.sleepAt != null,
            onTap: () => PlayerSheets.showSleepTimer(context),
          ),
          PillButton(
            icon: Icons.queue_music_rounded,
            label: s.queue,
            glass: true,
            onTap: () => PlayerSheets.showQueue(context),
          ),
        ],
      ),
    );
  }
}

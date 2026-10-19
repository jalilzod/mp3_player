import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../utils/song_display.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/position_data.dart';
import '../cubit/player/player_cubit.dart';
import '../cubit/player/player_state.dart';
import '../pages/player_page.dart';
import 'song_artwork.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerViewState>(
      buildWhen: (a, b) =>
          a.currentSong != b.currentSong ||
          a.isPlaying != b.isPlaying ||
          a.isBuffering != b.isBuffering,
      builder: (context, state) {
        final song = state.currentSong;
        final cubit = context.read<PlayerCubit>();

        return AnimatedSlide(
          offset: song == null ? const Offset(0, 1.5) : Offset.zero,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          child: song == null
              ? const SizedBox(height: 72)
              : GestureDetector(
                  onTap: () => PlayerPage.open(context),
                  onVerticalDragEnd: (d) {
                    if ((d.primaryVelocity ?? 0) < -200) PlayerPage.open(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(10, 10, 6, 8),
                                child: Row(
                                  children: [
                                    Hero(
                                      tag: 'now-playing-artwork',
                                      child: SongArtwork(
                                          song: song, size: 46, radius: 12),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 300),
                                        child: Column(
                                          key: ValueKey(song.id),
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(song.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15)),
                                            const SizedBox(height: 2),
                                            Text(song.artistText(context.s),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    color: AppColors.textSecondary,
                                                    fontSize: 12.5)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: cubit.previous,
                                      icon: const Icon(Icons.skip_previous_rounded),
                                    ),
                                    _PlayPauseSmall(
                                      isPlaying: state.isPlaying,
                                      isBuffering: state.isBuffering,
                                      onTap: cubit.togglePlay,
                                    ),
                                    IconButton(
                                      onPressed: cubit.next,
                                      icon: const Icon(Icons.skip_next_rounded),
                                    ),
                                  ],
                                ),
                              ),
                              StreamBuilder<PositionData>(
                                stream: cubit.positionStream,
                                builder: (_, snap) => LinearProgressIndicator(
                                  value: (snap.data ?? PositionData.zero).progress,
                                  minHeight: 2.5,
                                  backgroundColor: Colors.white12,
                                  valueColor: const AlwaysStoppedAnimation(
                                      AppColors.secondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _PlayPauseSmall extends StatelessWidget {
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTap;
  const _PlayPauseSmall(
      {required this.isPlaying, required this.isBuffering, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          gradient: AppColors.accentGradient,
          shape: BoxShape.circle,
        ),
        child: isBuffering
            ? const Padding(
                padding: EdgeInsets.all(11),
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(isPlaying),
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

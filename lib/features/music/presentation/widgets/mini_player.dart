import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/position_data.dart';
import '../../domain/entities/song.dart';
import '../cubit/player/player_cubit.dart';
import '../cubit/player/player_state.dart';
import '../pages/player_page.dart';
import '../utils/song_display.dart';
import 'pressable.dart';
import 'song_artwork.dart';

/// Floating frosted-glass player at the bottom of the home screen.
/// Tap / swipe up → full player. Swipe left / right → next / previous.
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
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) => SlideTransition(
            position: Tween(begin: const Offset(0, 1.3), end: Offset.zero)
                .animate(anim),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: state.currentSong == null
              ? const SizedBox.shrink(key: ValueKey('empty'))
              : _MiniPlayerCard(key: const ValueKey('card'), state: state),
        );
      },
    );
  }
}

class _MiniPlayerCard extends StatelessWidget {
  final PlayerViewState state;
  const _MiniPlayerCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlayerCubit>();
    final song = state.currentSong!;

    return GestureDetector(
      onTap: () => PlayerPage.open(context),
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) < -200) PlayerPage.open(context);
      },
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -300) {
          HapticFeedback.selectionClick();
          cubit.next();
        } else if (v > 300) {
          HapticFeedback.selectionClick();
          cubit.previous();
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: state.isPlaying ? 0.25 : 0.1),
                blurRadius: 30,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.surfaceLight.withValues(alpha: 0.82),
                      AppColors.surface.withValues(alpha: 0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 8, 8),
                      child: Row(
                        children: [
                          _SpinningDisc(song: song, isPlaying: state.isPlaying),
                          const SizedBox(width: 12),
                          Expanded(child: _SongText(song: song)),
                          _MiniPlayButton(
                            isPlaying: state.isPlaying,
                            isBuffering: state.isBuffering,
                            onTap: cubit.togglePlay,
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              cubit.next();
                            },
                            icon: const Icon(Icons.skip_next_rounded, size: 28),
                          ),
                        ],
                      ),
                    ),
                    _GradientProgress(stream: cubit.positionStream),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SongText extends StatelessWidget {
  final Song song;
  const _SongText({required this.song});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      // Keep text left-aligned while the old and new titles cross-fade.
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0.2, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      child: Column(
        key: ValueKey(song.id),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 2),
          Text(song.artistText(context.s),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        ],
      ),
    );
  }
}

/// Small record that spins while music plays.
class _SpinningDisc extends StatefulWidget {
  final Song song;
  final bool isPlaying;
  const _SpinningDisc({required this.song, required this.isPlaying});

  @override
  State<_SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<_SpinningDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying) _spin.repeat();
  }

  @override
  void didUpdateWidget(covariant _SpinningDisc old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.isPlaying && _spin.isAnimating) {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.accentGradient,
      ),
      child: RotationTransition(
        turns: _spin,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Hero(
              tag: 'now-playing-artwork',
              child: ClipOval(
                child: SongArtwork(song: widget.song, size: 45, radius: 22.5),
              ),
            ),
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPlayButton extends StatelessWidget {
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTap;
  const _MiniPlayButton({
    required this.isPlaying,
    required this.isBuffering,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          shape: BoxShape.circle,
          boxShadow: AppColors.glow(AppColors.primary, strength: 0.5),
        ),
        child: isBuffering
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (c, a) => RotationTransition(
                  turns: Tween(begin: 0.75, end: 1.0).animate(a),
                  child: ScaleTransition(scale: a, child: c),
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(isPlaying),
                  color: Colors.white,
                  size: 26,
                ),
              ),
      ),
    );
  }
}

class _GradientProgress extends StatelessWidget {
  final Stream<PositionData> stream;
  const _GradientProgress({required this.stream});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: StreamBuilder<PositionData>(
        stream: stream,
        builder: (_, snap) {
          final progress = (snap.data ?? PositionData.zero).progress;
          return ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LayoutBuilder(
              builder: (_, c) => Stack(
                children: [
                  Container(
                    height: 3,
                    width: c.maxWidth,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  Container(
                    height: 3,
                    width: c.maxWidth * progress,
                    decoration: const BoxDecoration(gradient: AppColors.accentGradient),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/player/player_cubit.dart';
import '../cubit/player/player_state.dart';
import '../utils/song_display.dart';
import 'equalizer_bars.dart';
import 'glass.dart';
import 'pressable.dart';
import 'song_artwork.dart';

class PlayerSheets {
  PlayerSheets._();

  /// "Up next" queue. Tap a song to jump to it.
  static void showQueue(BuildContext context) {
    final cubit = context.read<PlayerCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.92,
          builder: (context, controller) =>
              BlocBuilder<PlayerCubit, PlayerViewState>(
            builder: (context, state) => Column(
              children: [
                SheetTitle(context.s.upNext,
                    subtitle: context.s.songsCount(state.queue.length)),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: state.queue.length,
                    itemBuilder: (_, i) {
                      final song = state.queue[i];
                      final isCurrent = song.id == state.currentSong?.id;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: isCurrent
                              ? AppColors.primary.withValues(alpha: 0.16)
                              : Colors.transparent,
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          leading: SongArtwork(song: song, size: 46, radius: 12),
                          title: Text(song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isCurrent ? AppColors.primaryLight : Colors.white,
                                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                              )),
                          subtitle: Text(song.artistText(context.s),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textSecondary)),
                          trailing: isCurrent
                              ? EqualizerBars(animating: state.isPlaying)
                              : null,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            cubit.skipTo(song);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void showSpeed(BuildContext context) {
    final cubit = context.read<PlayerCubit>();
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetTitle(context.s.playbackSpeed),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: AppConstants.playbackSpeeds.map((speed) {
                  final selected = cubit.state.speed == speed;
                  return Pressable(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      cubit.setSpeed(speed);
                      Navigator.pop(sheetContext);
                    },
                    child: Container(
                      width: 92,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: selected ? AppColors.accentGradient : null,
                        color: selected ? null : AppColors.glass,
                        border: selected
                            ? null
                            : Border.all(color: AppColors.glassBorder),
                        boxShadow: selected
                            ? AppColors.glow(AppColors.primary, strength: 0.5)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text('${speed}x',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white : AppColors.textSecondary,
                          )),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showSleepTimer(BuildContext context) {
    final cubit = context.read<PlayerCubit>();
    final active = cubit.state.sleepAt;
    final s = context.s;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetTitle(
                s.sleepTimer,
                subtitle: active == null
                    ? null
                    : s.stopsInMinutes(active.difference(DateTime.now()).inMinutes + 1),
              ),
              ...AppConstants.sleepTimerOptions.map((d) => SheetOption(
                    icon: Icons.bedtime_outlined,
                    label: s.durationOption(d),
                    onTap: () {
                      cubit.setSleepTimer(d);
                      Navigator.pop(sheetContext);
                    },
                  )),
              if (active != null)
                SheetOption(
                  icon: Icons.timer_off_outlined,
                  label: s.turnOffTimer,
                  danger: true,
                  onTap: () {
                    cubit.setSleepTimer(null);
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

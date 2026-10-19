import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../utils/song_display.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/player/player_cubit.dart';
import '../cubit/player/player_state.dart';
import 'equalizer_bars.dart';
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(context.s.upNext,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: state.queue.length,
                    itemBuilder: (_, i) {
                      final song = state.queue[i];
                      final isCurrent = song.id == state.currentSong?.id;
                      return ListTile(
                        leading: SongArtwork(song: song, size: 44, radius: 10),
                        title: Text(song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCurrent ? AppColors.secondary : Colors.white,
                              fontWeight: FontWeight.w600,
                            )),
                        subtitle: Text(song.artistText(context.s),
                            maxLines: 1,
                            style: const TextStyle(color: AppColors.textSecondary)),
                        trailing: isCurrent
                            ? EqualizerBars(animating: state.isPlaying)
                            : null,
                        onTap: () => cubit.skipTo(song),
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
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.s.playbackSpeed,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: AppConstants.playbackSpeeds.map((s) {
                  final selected = cubit.state.speed == s;
                  return ChoiceChip(
                    label: Text('${s}x'),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    onSelected: (_) {
                      cubit.setSpeed(s);
                      Navigator.pop(context);
                    },
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
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.sleepTimer,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            if (active != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  s.stopsInMinutes(
                      active.difference(DateTime.now()).inMinutes + 1),
                  style: const TextStyle(color: AppColors.secondary),
                ),
              ),
            const SizedBox(height: 8),
            ...AppConstants.sleepTimerOptions.map((d) => ListTile(
                  leading: const Icon(Icons.bedtime_outlined),
                  title: Text(s.durationOption(d)),
                  onTap: () {
                    cubit.setSleepTimer(d);
                    Navigator.pop(context);
                  },
                )),
            if (active != null)
              ListTile(
                leading: const Icon(Icons.timer_off_outlined,
                    color: AppColors.secondary),
                title: Text(s.turnOffTimer,
                    style: const TextStyle(color: AppColors.secondary)),
                onTap: () {
                  cubit.setSleepTimer(null);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

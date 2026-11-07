import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/song.dart';
import '../cubit/library/library_cubit.dart';
import '../cubit/player/player_cubit.dart';

/// Actions that touch both the library and the player.
class SongActions {
  SongActions._();

  /// Removes the song from the queue and the list. The library shows an
  /// "Undo" snackbar; the file is really deleted after a few seconds.
  static void delete(BuildContext context, Song song) {
    HapticFeedback.mediumImpact();
    context.read<PlayerCubit>().removeSong(song);
    context.read<LibraryCubit>().deleteSong(song);
  }
}

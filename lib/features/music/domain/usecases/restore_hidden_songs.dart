import '../repositories/music_repository.dart';

class RestoreHiddenSongs {
  final MusicRepository _repository;
  const RestoreHiddenSongs(this._repository);

  Future<void> call() => _repository.restoreHiddenSongs();
}

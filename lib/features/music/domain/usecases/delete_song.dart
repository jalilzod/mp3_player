import '../entities/song.dart';
import '../repositories/music_repository.dart';

class DeleteSong {
  final MusicRepository _repository;
  const DeleteSong(this._repository);

  Future<void> call(Song song) => _repository.deleteSong(song);
}

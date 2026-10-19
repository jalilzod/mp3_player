import '../entities/song.dart';
import '../repositories/music_repository.dart';

class GetSongs {
  final MusicRepository _repository;
  const GetSongs(this._repository);

  Future<List<Song>> call() => _repository.getSongs();
}

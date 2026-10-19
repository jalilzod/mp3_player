import '../repositories/music_repository.dart';

class ToggleFavorite {
  final MusicRepository _repository;
  const ToggleFavorite(this._repository);

  Future<Set<String>> call(String songId) => _repository.toggleFavorite(songId);
}

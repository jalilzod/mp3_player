import '../repositories/music_repository.dart';

class GetFavoriteIds {
  final MusicRepository _repository;
  const GetFavoriteIds(this._repository);

  Future<Set<String>> call() => _repository.getFavoriteIds();
}

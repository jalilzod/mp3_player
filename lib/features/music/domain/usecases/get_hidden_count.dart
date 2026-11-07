import '../repositories/music_repository.dart';

class GetHiddenCount {
  final MusicRepository _repository;
  const GetHiddenCount(this._repository);

  Future<int> call() => _repository.getHiddenCount();
}

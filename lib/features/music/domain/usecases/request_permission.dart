import '../repositories/music_repository.dart';

class RequestPermission {
  final MusicRepository _repository;
  const RequestPermission(this._repository);

  Future<bool> call() => _repository.requestPermission();
}

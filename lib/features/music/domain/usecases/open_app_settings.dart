import '../repositories/music_repository.dart';

class OpenAppSettings {
  final MusicRepository _repository;
  const OpenAppSettings(this._repository);

  Future<void> call() => _repository.openAppSettings();
}

import '../repositories/music_repository.dart';

class ImportSongs {
  final MusicRepository _repository;
  const ImportSongs(this._repository);

  Future<int> call() => _repository.importSongs();
}

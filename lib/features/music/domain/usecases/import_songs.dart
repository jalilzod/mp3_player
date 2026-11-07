import '../entities/import_result.dart';
import '../repositories/music_repository.dart';

class ImportSongs {
  final MusicRepository _repository;
  const ImportSongs(this._repository);

  Future<ImportResult> call() => _repository.importSongs();
}

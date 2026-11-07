/// Outcome of picking files to import.
class ImportResult {
  /// Songs copied into the library.
  final int added;

  /// Songs skipped because they were already in the library.
  final int skipped;

  /// True when the user closed the picker without choosing anything.
  final bool cancelled;

  const ImportResult({this.added = 0, this.skipped = 0, this.cancelled = false});

  const ImportResult.cancelled() : this(cancelled: true);
}

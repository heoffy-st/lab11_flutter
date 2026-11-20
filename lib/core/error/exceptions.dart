class DatabaseException implements Exception {
  final String message;
  const DatabaseException(this.message);

  @override
  String toString() => message;
}

class UnexpectedException implements Exception {
  final String message;
  const UnexpectedException(this.message);

  @override
  String toString() => message;
}

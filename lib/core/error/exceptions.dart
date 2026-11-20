class DatabaseException implements Exception {
  final String message;
  const DatabaseException([this.message = 'Ошибка при работе с локальными данными']);
}

class NetworkException implements Exception {
  const NetworkException();
}

class ServerException implements Exception {
  final int statusCode;
  const ServerException(this.statusCode);
}

class UnauthorizedException implements Exception {
  const UnauthorizedException();
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
}

class UnexpectedException implements Exception {
  const UnexpectedException();
}

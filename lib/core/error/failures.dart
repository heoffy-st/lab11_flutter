abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('Нет подключения к сети. Проверьте соединение.');
}

class ServerFailure extends Failure {
  const ServerFailure() : super('Сервер временно недоступен. Попробуйте позже.');
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure() : super('Необходима авторизация.');
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Проверьте корректность введённых данных.']);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Ошибка при работе с локальной базой данных.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure() : super('Произошла непредвиденная ошибка. Попробуйте ещё раз.');
}

/// Kept as a compatibility alias for older parts of the application.
class UnexpectedFailure extends UnknownFailure {
  const UnexpectedFailure();
}

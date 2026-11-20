abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Ошибка при работе с базой данных']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Произошла непредвиденная ошибка']);
}

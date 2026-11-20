import 'exceptions.dart';
import 'failures.dart';

class ErrorMapper {
  const ErrorMapper._();

  static Failure toFailure(Object error) {
    if (error is DatabaseException) {
      return DatabaseFailure(error.message);
    }
    if (error is Failure) {
      return error;
    }
    return const UnexpectedFailure();
  }
}

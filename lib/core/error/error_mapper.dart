import 'dart:async';

import 'exceptions.dart';
import 'failures.dart';

class ErrorMapper {
  const ErrorMapper._();

  static Failure toFailure(Object error) {
    if (error is Failure) return error;
    if (error is NetworkException || error is TimeoutException) {
      return const NetworkFailure();
    }
    if (error is UnauthorizedException) {
      return const UnauthorizedFailure();
    }
    if (error is ServerException) {
      if (error.statusCode == 401) return const UnauthorizedFailure();
      if (error.statusCode == 400) return const ValidationFailure();
      if (error.statusCode >= 500) return const ServerFailure();
      return const UnknownFailure();
    }
    if (error is ValidationException) {
      return ValidationFailure(error.message);
    }
    if (error is ArgumentError || error is FormatException || error is StateError) {
      return const ValidationFailure();
    }
    if (error is DatabaseException) {
      return const DatabaseFailure();
    }
    if (error is UnexpectedException) {
      return const UnknownFailure();
    }
    return const UnknownFailure();
  }

  /// Maps failures raised by the SQLite/Drift data source.
  /// Validation errors keep their meaning; unexpected storage errors are
  /// exposed as a safe database failure rather than a raw exception.
  static Failure toDataFailure(Object error) {
    if (error is ArgumentError ||
        error is FormatException ||
        error is StateError ||
        error is Failure ||
        error is NetworkException ||
        error is TimeoutException ||
        error is ServerException ||
        error is UnauthorizedException ||
        error is ValidationException ||
        error is UnexpectedException) {
      return toFailure(error);
    }
    if (error is DatabaseException) return toFailure(error);
    return const DatabaseFailure();
  }
}

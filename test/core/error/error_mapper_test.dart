import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/error/error_mapper.dart';
import 'package:taskflow/core/error/exceptions.dart';
import 'package:taskflow/core/error/failures.dart';

void main() {
  group('ErrorMapper', () {
    test('maps network errors', () {
      expect(ErrorMapper.toFailure(const NetworkException()), isA<NetworkFailure>());
      expect(ErrorMapper.toFailure(TimeoutException('timeout')), isA<NetworkFailure>());
    });

    test('maps server errors', () {
      expect(ErrorMapper.toFailure(const ServerException(500)), isA<ServerFailure>());
    });

    test('maps authorization errors', () {
      expect(
        ErrorMapper.toFailure(const UnauthorizedException()),
        isA<UnauthorizedFailure>(),
      );
    });

    test('maps validation errors without exposing technical details', () {
      final failure = ErrorMapper.toFailure(ArgumentError('SQL constraint'));
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, isNot(contains('SQL constraint')));
    });

    test('maps database errors', () {
      expect(
        ErrorMapper.toFailure(const DatabaseException()),
        isA<DatabaseFailure>(),
      );
    });

    test('maps unknown errors to a safe user message', () {
      final failure = ErrorMapper.toFailure(Exception('internal stack details'));
      expect(failure, isA<UnknownFailure>());
      expect(failure.message, isNot(contains('internal stack details')));
    });

    test('preserves an already mapped failure', () {
      const failure = NetworkFailure();
      expect(identical(ErrorMapper.toFailure(failure), failure), isTrue);
    });
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Failure.from', () {
    test('timeouts are network failures', () {
      expect(Failure.from(TimeoutException('x')), isA<NetworkFailure>());
    });

    test('auth errors and permission-denied rows are auth failures', () {
      expect(Failure.from(const AuthException('bad')), isA<AuthFailure>());
      expect(
        Failure.from(const PostgrestException(message: 'no', code: '42501')),
        isA<AuthFailure>(),
      );
    });

    test('other backend errors are server failures', () {
      expect(
        Failure.from(const PostgrestException(message: 'boom', code: '23505')),
        isA<ServerFailure>(),
      );
    });

    test('anything else is unknown and keeps its cause', () {
      final failure = Failure.from(StateError('x'));
      expect(failure, isA<UnknownFailure>());
      expect(failure.cause, isA<StateError>());
    });

    test('an existing failure passes through unchanged', () {
      const original = NetworkFailure();
      expect(identical(Failure.from(original), original), isTrue);
    });
  });

  test('guardFailure rethrows typed failures', () async {
    await expectLater(
      guardFailure<void>(() async => throw TimeoutException('x')),
      throwsA(isA<NetworkFailure>()),
    );
    expect(await guardFailure(() async => 42), 42);
  });
}

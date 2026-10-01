import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/core/error/failure_messages.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SocketException implements Exception {}

class HandshakeException implements Exception {}

class ClientException implements Exception {}

void main() {
  group('Failure.from', () {
    test('retryable fetch errors are network failures', () {
      expect(
        Failure.from(AuthRetryableFetchException(message: 'offline')),
        isA<NetworkFailure>(),
      );
    });

    test('PostgREST auth codes map to AuthFailure', () {
      for (final code in ['42501', 'PGRST301', '401']) {
        expect(
          Failure.from(PostgrestException(message: 'x', code: code)),
          isA<AuthFailure>(),
          reason: code,
        );
      }
    });

    test('storage errors depend on the status code', () {
      expect(
        Failure.from(const StorageException('no', statusCode: '403')),
        isA<AuthFailure>(),
      );
      expect(
        Failure.from(const StorageException('no', statusCode: '401')),
        isA<AuthFailure>(),
      );
      expect(
        Failure.from(const StorageException('boom', statusCode: '500')),
        isA<ServerFailure>(),
      );
    });

    test('socket-like errors are matched by type name', () {
      expect(Failure.from(SocketException()), isA<NetworkFailure>());
      expect(Failure.from(HandshakeException()), isA<NetworkFailure>());
      expect(Failure.from(ClientException()), isA<NetworkFailure>());
    });

    test('toString names the type and cause', () {
      expect(const UnknownFailure('x').toString(), 'UnknownFailure(x)');
      expect(const NetworkFailure().toString(), 'NetworkFailure()');
    });
  });

  test('guardFailure maps and keeps typed failures as they are', () async {
    await expectLater(
      guardFailure<void>(() async => throw const AuthException('bad')),
      throwsA(isA<AuthFailure>()),
    );
    await expectLater(
      guardFailure<void>(() async => throw const ServerFailure()),
      throwsA(isA<ServerFailure>()),
    );
    await expectLater(
      guardFailure<void>(() async => throw TimeoutException('t')),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('failureDetail explains every failure but unknown ones', () {
    final l10n = AppLocalizationsEs();
    expect(
      failureDetail(l10n, const NetworkFailure()),
      l10n.commonErrorNetwork,
    );
    expect(failureDetail(l10n, const AuthFailure()), l10n.commonErrorSession);
    expect(failureDetail(l10n, const ServerFailure()), l10n.commonErrorServer);
    expect(failureDetail(l10n, const UnknownFailure()), isNull);
  });
}

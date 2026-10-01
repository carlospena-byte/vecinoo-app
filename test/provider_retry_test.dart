import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/core/error/provider_retry.dart';

void main() {
  test('a missing session is never retried', () {
    expect(providerRetry(0, const AuthFailure()), isNull);
  });

  test('transient failures keep the default backoff', () {
    expect(providerRetry(0, const NetworkFailure()), isNotNull);
    expect(providerRetry(0, const ServerFailure()), isNotNull);
  });

  test('a provider failing with AuthFailure runs exactly once', () async {
    var runs = 0;
    final provider = FutureProvider<int>((ref) {
      runs++;
      throw const AuthFailure();
    });
    final container = ProviderContainer(retry: providerRetry);
    addTearDown(container.dispose);
    container.listen(provider, (_, _) {});

    await Future<void>.delayed(const Duration(milliseconds: 900));

    expect(runs, 1);
  });

  test('a network failure is retried', () async {
    var runs = 0;
    final provider = FutureProvider<int>((ref) {
      runs++;
      throw TimeoutException('slow');
    });
    final container = ProviderContainer(retry: providerRetry);
    addTearDown(container.dispose);
    container.listen(provider, (_, _) {});

    await Future<void>.delayed(const Duration(milliseconds: 900));

    expect(runs, greaterThan(1));
  });
}

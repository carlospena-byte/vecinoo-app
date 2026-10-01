import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// A typed failure raised by the data layer, so presentation code can react
/// to *what* went wrong (no connection, expired session...) instead of
/// catching everything with `catch (_)`.
sealed class Failure implements Exception {
  const Failure([this.cause]);

  /// The original error, kept for logging.
  final Object? cause;

  /// Maps any thrown error to a [Failure]. Already-mapped failures pass
  /// through untouched.
  factory Failure.from(Object error) {
    if (error is Failure) return error;
    if (error is TimeoutException) return NetworkFailure(error);
    if (error is AuthRetryableFetchException) return NetworkFailure(error);
    if (error is AuthException) return AuthFailure(error);
    if (error is PostgrestException) {
      final code = error.code;
      return code == '42501' || code == 'PGRST301' || code == '401'
          ? AuthFailure(error)
          : ServerFailure(error);
    }
    if (error is StorageException) {
      final status = error.statusCode;
      return status == '401' || status == '403'
          ? AuthFailure(error)
          : ServerFailure(error);
    }
    // dart:io's SocketException/HandshakeException and package:http's
    // ClientException are matched by name to keep this layer free of
    // platform imports.
    final type = error.runtimeType.toString();
    if (type == 'SocketException' ||
        type == 'HandshakeException' ||
        type == 'ClientException' ||
        type == '_ClientSocketException') {
      return NetworkFailure(error);
    }
    return UnknownFailure(error);
  }

  @override
  String toString() => '$runtimeType(${cause ?? ''})';
}

/// No connection / timeout: retrying later may work.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.cause]);
}

/// Not signed in, expired session or insufficient permissions.
final class AuthFailure extends Failure {
  const AuthFailure([super.cause]);
}

/// The backend rejected or failed the request.
final class ServerFailure extends Failure {
  const ServerFailure([super.cause]);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.cause]);
}

/// Runs [body] and rethrows any error as a [Failure].
Future<T> guardFailure<T>(Future<T> Function() body) async {
  try {
    return await body();
  } catch (error, stackTrace) {
    final failure = Failure.from(error);
    if (identical(failure, error)) rethrow;
    Error.throwWithStackTrace(failure, stackTrace);
  }
}

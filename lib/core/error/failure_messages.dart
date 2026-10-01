import '../../l10n/l10n.dart';
import 'failure.dart';

/// Short, user-facing explanation of a [Failure], or null when the failure
/// carries nothing more useful than the caller's own message.
String? failureDetail(AppLocalizations l10n, Failure failure) {
  return switch (failure) {
    NetworkFailure() => l10n.commonErrorNetwork,
    AuthFailure() => l10n.commonErrorSession,
    ServerFailure() => l10n.commonErrorServer,
    UnknownFailure() => null,
  };
}

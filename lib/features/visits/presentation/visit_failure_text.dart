import '../../../core/error/failure.dart';
import '../../../core/error/failure_messages.dart';
import '../../../l10n/l10n.dart';

/// Prefixes [fallback] with the user-facing cause of [failure] (no
/// connection, expired session...) when there is one.
String withFailureDetail(
  AppLocalizations l10n,
  Failure failure,
  String fallback,
) {
  final detail = failureDetail(l10n, failure);
  return detail == null ? fallback : '$detail $fallback';
}

/// Same as [withFailureDetail] for a raw error caught in a provider's
/// `AsyncValue.error`.
String withErrorDetail(AppLocalizations l10n, Object error, String fallback) =>
    withFailureDetail(l10n, Failure.from(error), fallback);

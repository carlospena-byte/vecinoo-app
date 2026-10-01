import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'failure.dart';

/// Retry policy for providers (Riverpod 3 retries any thrown `Exception` by
/// default). Permanent failures — no session, no permission — must not be
/// retried: each retry re-emits the provider, which refreshes the router and
/// the screens that depend on it. Everything else keeps Riverpod's default
/// exponential backoff.
Duration? providerRetry(int retryCount, Object error) {
  if (error is AuthFailure) return null;
  return ProviderContainer.defaultRetry(retryCount, error);
}

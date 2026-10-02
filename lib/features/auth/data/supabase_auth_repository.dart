import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../domain/auth_repository.dart';

/// Supabase-backed [AuthRepository]. Passwordless only (see the interface).
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  /// Store-review account. Its code is fixed and checked server-side by the
  /// `review-login` Edge Function (gates-admin), which hands back a real
  /// one-time token; no email is sent for it.
  static const _reviewEmail = 'demo@vecinoo.app';

  static bool _isReviewEmail(String email) =>
      email.trim().toLowerCase() == _reviewEmail;

  static SignedInUser? _toUser(User? user) =>
      user == null ? null : SignedInUser(id: user.id, email: user.email);

  @override
  Stream<SignedInUser?> get userChanges => _client.auth.onAuthStateChange.map(
    (state) => _toUser(state.session?.user),
  );

  @override
  SignedInUser? get currentUser => _toUser(_client.auth.currentUser);

  /// Sends a 6-digit code to [email] (see supabase/templates/magic_link.html
  /// in gates-admin, which overrides Supabase's default link-only template
  /// to show `{{ .Token }}`). Creates the auth user on first use.
  @override
  Future<OtpSendOutcome> sendEmailOtp(String email) => _isReviewEmail(email)
      ? Future.value(OtpSendOutcome.sent)
      : _send(() => _client.auth.signInWithOtp(email: email));

  @override
  Future<OtpVerifyOutcome> verifyEmailOtp({
    required String email,
    required String token,
  }) => _verify(() async {
    var otp = token;
    if (_isReviewEmail(email)) {
      try {
        final res = await _client.functions.invoke(
          'review-login',
          body: {'email': email, 'code': token},
        );
        otp = (res.data as Map)['token'] as String;
      } on FunctionException catch (e) {
        // Wrong code (401) or account not provisioned (404): surface it as a
        // rejected code rather than a generic failure.
        if (e.status == 401 || e.status == 404) {
          throw const AuthApiException('invalid code', statusCode: '400');
        }
        rethrow;
      }
    }
    await _client.auth.verifyOTP(email: email, token: otp, type: OtpType.email);
  });

  @override
  Future<OtpSendOutcome> sendPhoneOtp(String phone) =>
      _send(() => _client.auth.signInWithOtp(phone: phone));

  @override
  Future<OtpVerifyOutcome> verifyPhoneOtp({
    required String phone,
    required String token,
  }) => _verify(
    () => _client.auth.verifyOTP(phone: phone, token: token, type: OtpType.sms),
  );

  @override
  Future<void> signOut() => guardFailure(() => _client.auth.signOut());

  Future<OtpSendOutcome> _send(Future<void> Function() body) =>
      guardFailure(() async {
        try {
          await body();
          return OtpSendOutcome.sent;
        } on AuthApiException catch (e) {
          if (_isRateLimit(e)) return OtpSendOutcome.rateLimited;
          rethrow;
        }
      });

  Future<OtpVerifyOutcome> _verify(Future<void> Function() body) =>
      guardFailure(() async {
        try {
          await body();
          return OtpVerifyOutcome.verified;
        } on AuthApiException catch (e) {
          if (_isInvalidCode(e)) return OtpVerifyOutcome.invalidCode;
          rethrow;
        }
      });

  static bool _isRateLimit(AuthApiException e) =>
      e.statusCode == '429' || (e.code ?? '').contains('rate_limit');

  /// A rejected code (wrong/expired), as opposed to a rate limit or a
  /// server-side error.
  static bool _isInvalidCode(AuthApiException e) {
    if (_isRateLimit(e)) return false;
    final status = int.tryParse(e.statusCode ?? '');
    return status == null || (status >= 400 && status < 500);
  }
}

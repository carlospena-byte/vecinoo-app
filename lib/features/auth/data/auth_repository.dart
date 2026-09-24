import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase Auth. Passwordless only: every resident
/// signs in with a one-time code, sent to their email or phone — there's
/// no password to set, forget, or leak.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  /// Sends a 6-digit code to [email] (see supabase/templates/magic_link.html
  /// in gates-admin, which overrides Supabase's default link-only template
  /// to show `{{ .Token }}`). Creates the auth user on first use.
  Future<void> sendEmailOtp(String email) {
    return _client.auth.signInWithOtp(email: email);
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) {
    return _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  /// Sends an OTP code to [phone] (E.164 format, e.g. +50412345678).
  /// Creates the auth user on first use.
  Future<void> sendPhoneOtp(String phone) {
    return _client.auth.signInWithOtp(phone: phone);
  }

  Future<void> verifyPhoneOtp({
    required String phone,
    required String token,
  }) {
    return _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}

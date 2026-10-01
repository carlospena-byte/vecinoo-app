/// The signed-in user, as far as the app cares: no backend types leak out
/// of the data layer.
class SignedInUser {
  const SignedInUser({required this.id, this.email});

  final String id;
  final String? email;
}

/// Result of asking for a one-time code.
enum OtpSendOutcome {
  sent,

  /// Too many codes requested recently; try again after a cooldown.
  rateLimited,
}

/// Result of checking a one-time code.
enum OtpVerifyOutcome {
  verified,

  /// The code is wrong or has expired.
  invalidCode,
}

/// What the auth feature needs from the backend. Passwordless only: every
/// resident signs in with a one-time code sent to their email or phone.
/// Implementations throw `Failure`s (see core/error/failure.dart), never raw
/// backend exceptions; expected outcomes (wrong code, rate limit) are
/// returned as values instead.
abstract interface class AuthRepository {
  /// Emits the signed-in user (or null) on every auth change: sign in, sign
  /// out, token refresh.
  Stream<SignedInUser?> get userChanges;

  SignedInUser? get currentUser;

  /// Sends a 6-digit code to [email]. Creates the auth user on first use.
  Future<OtpSendOutcome> sendEmailOtp(String email);

  Future<OtpVerifyOutcome> verifyEmailOtp({
    required String email,
    required String token,
  });

  /// Sends an OTP code to [phone] (E.164 format, e.g. +50412345678).
  Future<OtpSendOutcome> sendPhoneOtp(String phone);

  Future<OtpVerifyOutcome> verifyPhoneOtp({
    required String phone,
    required String token,
  });

  Future<void> signOut();
}

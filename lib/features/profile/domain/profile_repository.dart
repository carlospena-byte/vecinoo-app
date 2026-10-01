import 'dart:typed_data';

import '../../auth/domain/auth_repository.dart';
import 'profile.dart';

/// What the profile feature needs from the backend. Implementations throw
/// `Failure`s (see core/error/failure.dart), never raw backend exceptions.
abstract interface class ProfileRepository {
  Future<Profile> fetchMine();

  Future<void> updateMine({String? firstName, String? lastName, String? phone});

  /// Uploads [bytes] as the user's new photo and returns its public URL.
  /// [extension] is the file type without the dot (`jpg`, `png`, `webp`).
  Future<String> uploadAvatar(Uint8List bytes, String extension);

  /// Sends a 6-digit code to [newEmail]. The email only changes once
  /// [confirmEmailChange] succeeds.
  Future<OtpSendOutcome> requestEmailChange(String newEmail);

  Future<OtpVerifyOutcome> confirmEmailChange({
    required String newEmail,
    required String token,
  });

  /// Schedules the account for permanent deletion after one calendar month
  /// and returns that date. Idempotent: asking again keeps the first date.
  Future<DateTime> requestAccountDeletion();

  Future<void> cancelAccountDeletion();
}

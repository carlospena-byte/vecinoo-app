import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';

const _avatarsBucket = 'avatars';

/// Supabase-backed [ProfileRepository]; every call surfaces errors as
/// `Failure`s.
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthFailure();
    return userId;
  }

  @override
  Future<Profile> fetchMine() => guardFailure(() async {
    final userId = _requireUserId();
    final row = await _client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .single();
    return Profile.fromMap(row);
  });

  @override
  Future<void> updateMine({
    String? firstName,
    String? lastName,
    String? phone,
  }) => guardFailure(() async {
    final userId = _requireUserId();
    final updates = <String, dynamic>{};
    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (phone != null) updates['phone'] = phone;
    if (updates.isEmpty) return;
    await _client.from('profiles').update(updates).eq('user_id', userId);
  });

  @override
  Future<String> uploadAvatar(Uint8List bytes, String extension) =>
      guardFailure(() async {
        final userId = _requireUserId();
        final ext = extension.toLowerCase();
        // A new path per upload sidesteps CDN/image caches serving the old
        // photo; the previous files are removed afterwards.
        final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
        final storage = _client.storage.from(_avatarsBucket);
        final previous = await storage.list(path: userId);
        await storage.uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: _mimeType(ext)),
        );
        final url = storage.getPublicUrl(path);
        await _client
            .from('profiles')
            .update({'avatar_url': url})
            .eq('user_id', userId);
        if (previous.isNotEmpty) {
          await storage.remove([for (final f in previous) '$userId/${f.name}']);
        }
        return url;
      });

  static String _mimeType(String ext) => switch (ext) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };

  /// Supabase sends the code to the new address when the email of a signed-in
  /// user is updated (see supabase/templates/email_change.html in
  /// gates-admin); the change is applied on verification.
  @override
  Future<OtpSendOutcome> requestEmailChange(String newEmail) =>
      guardFailure(() async {
        try {
          await _client.auth.updateUser(UserAttributes(email: newEmail));
          return OtpSendOutcome.sent;
        } on AuthApiException catch (e) {
          if (_isRateLimit(e)) return OtpSendOutcome.rateLimited;
          rethrow;
        }
      });

  @override
  Future<OtpVerifyOutcome> confirmEmailChange({
    required String newEmail,
    required String token,
  }) => guardFailure(() async {
    try {
      await _client.auth.verifyOTP(
        email: newEmail,
        token: token,
        type: OtpType.emailChange,
      );
      return OtpVerifyOutcome.verified;
    } on AuthApiException catch (e) {
      if (_isRateLimit(e)) rethrow;
      final status = int.tryParse(e.statusCode ?? '');
      if (status == null || (status >= 400 && status < 500)) {
        return OtpVerifyOutcome.invalidCode;
      }
      rethrow;
    }
  });

  @override
  Future<DateTime> requestAccountDeletion() => guardFailure(() async {
    _requireUserId();
    final result = await _client.rpc('request_account_deletion');
    return DateTime.parse(result as String).toLocal();
  });

  @override
  Future<void> cancelAccountDeletion() => guardFailure(() async {
    _requireUserId();
    await _client.rpc('cancel_account_deletion');
  });

  static bool _isRateLimit(AuthApiException e) =>
      e.statusCode == '429' || (e.code ?? '').contains('rate_limit');
}

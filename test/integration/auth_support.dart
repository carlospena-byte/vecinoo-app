import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/local_supabase.dart';

const mailpitUrl = 'http://127.0.0.1:8025';

String uniqueTestEmail(String prefix) =>
    '$prefix-${Random().nextInt(1 << 32).toRadixString(36)}@gates.test';

/// Polls Mailpit for the 6-digit login code sent to [email].
Future<String> readOtpFor(String email) async {
  final http = HttpClient();
  try {
    for (var i = 0; i < 40; i++) {
      final req = await http.getUrl(
        Uri.parse('$mailpitUrl/api/v1/search')
            .replace(queryParameters: {'query': 'to:$email'}),
      );
      final res = await req.close();
      final body = jsonDecode(
        await res.transform(utf8.decoder).join(),
      ) as Map<String, dynamic>;
      final messages = (body['messages'] as List?) ?? const [];
      for (final m in messages) {
        final match = RegExp(
          r'\b(\d{6})\b',
        ).firstMatch((m as Map<String, dynamic>)['Snippet'] as String? ?? '');
        if (match != null) return match.group(1)!;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  } finally {
    http.close(force: true);
  }
  throw StateError('No OTP email arrived for $email');
}

/// Deletes the auth user (and its memberships) registered under [email].
Future<void> deleteUserByEmail(SupabaseClient service, String email) async {
  try {
    final rows = await service
        .from('profiles')
        .select('user_id')
        .eq('email', email);
    for (final row in rows) {
      final id = row['user_id'] as String;
      await service.from('unit_members').delete().eq('user_id', id);
      await service.auth.admin.deleteUser(id);
    }
  } catch (_) {}
}

/// A confirmed user with a password and no unit memberships.
class BareUser {
  BareUser._(this.userId, this.email, this.client, this.service);

  final String userId;
  final String email;
  final SupabaseClient client;
  final SupabaseClient service;

  static Future<BareUser> create() async {
    final service = newServiceClient();
    final email = uniqueTestEmail('test-bare');
    final created = await service.auth.admin.createUser(
      AdminUserAttributes(
        email: email,
        password: 'test-password-123',
        emailConfirm: true,
      ),
    );
    final client = newAnonClient();
    await client.auth.signInWithPassword(
      email: email,
      password: 'test-password-123',
    );
    return BareUser._(created.user!.id, email, client, service);
  }

  Future<void> dispose() async {
    try {
      await service.from('unit_members').delete().eq('user_id', userId);
      await service.auth.admin.deleteUser(userId);
    } catch (_) {}
    await client.auth.signOut();
    await client.dispose();
    await service.dispose();
  }
}

/// Inserts a unit invitation for the demo unit and returns its (id, code).
Future<({String id, String code})> insertInvitation(
  SupabaseClient service, {
  required String email,
  String status = 'pending',
  Duration expiresIn = const Duration(hours: 24),
}) async {
  final code = (100000 + Random().nextInt(900000)).toString();
  final row = await service
      .from('unit_invitations')
      .insert({
        'unit_id': demoUnitId,
        'residential_id': demoResidentialId,
        'email': email,
        'code': code,
        'status': status,
        'expires_at': DateTime.now().add(expiresIn).toUtc().toIso8601String(),
      })
      .select('id')
      .single();
  return (id: row['id'] as String, code: code);
}

class _MemoryAsyncStorage extends GotrueAsyncStorage {
  final _data = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _data[key];

  @override
  Future<void> removeItem({required String key}) async => _data.remove(key);

  @override
  Future<void> setItem({required String key, required String value}) async =>
      _data[key] = value;
}

/// Anon client with in-memory PKCE storage (as the app has), needed by
/// `signInWithOtp`.
SupabaseClient newPkceAnonClient() {
  String? key;
  for (final line in File('.env.development').readAsLinesSync()) {
    if (line.startsWith('SUPABASE_PUBLISHABLE_KEY=')) {
      key = line.substring('SUPABASE_PUBLISHABLE_KEY='.length).trim();
    }
  }
  return SupabaseClient(
    localSupabaseUrl,
    key!,
    authOptions: AuthClientOptions(pkceAsyncStorage: _MemoryAsyncStorage()),
  );
}

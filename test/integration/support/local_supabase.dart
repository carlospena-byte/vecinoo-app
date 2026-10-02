import 'dart:io';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Helpers for tests that run against the local Supabase stack started from
/// `gates-admin` (`supabase start`). Everything they create is removed again
/// by [TestResident.dispose].
const localSupabaseUrl = 'http://127.0.0.1:64321';

/// Seeded by gates-admin/supabase/seed.sql.
const demoResidentialId = '550e8400-e29b-41d4-a716-446655440000';
const demoUnitId = '791d1d08-5a10-487d-8d17-039b9e637030';

String _readEnv(String key) {
  for (final line in File('.env.development').readAsLinesSync()) {
    if (line.startsWith('$key=')) return line.substring(key.length + 1).trim();
  }
  throw StateError('$key missing in .env.development');
}

/// Local-stack service-role key: the CLI's well-known demo key unless
/// `SUPABASE_SERVICE_ROLE_KEY` overrides it.
String get _serviceRoleKey =>
    Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ??
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';

/// Non-null (a skip reason) when the local stack can't be reached; pass it
/// to `test(..., skip: localSupabaseSkipReason)`.
final String? localSupabaseSkipReason = _probe();

String? _probe() {
  try {
    final result = Process.runSync('curl', [
      '-s',
      '-m',
      '2',
      '-o',
      '/dev/null',
      '-w',
      '%{http_code}',
      '$localSupabaseUrl/auth/v1/health',
    ]);
    return result.stdout.toString().trim() == '200'
        ? null
        : 'local Supabase is not running (supabase start in gates-admin)';
  } catch (_) {
    return 'curl is not available to probe local Supabase';
  }
}

SupabaseClient newAnonClient() =>
    SupabaseClient(localSupabaseUrl, _readEnv('SUPABASE_PUBLISHABLE_KEY'));

SupabaseClient newServiceClient() =>
    SupabaseClient(localSupabaseUrl, _serviceRoleKey);

/// A throwaway resident of the demo unit 101, signed in with its own
/// client (so RLS applies exactly as in the app).
class TestResident {
  TestResident._({
    required this.userId,
    required this.email,
    required this.client,
    required this.service,
  });

  final String userId;
  final String email;

  /// Authenticated as the resident — what the repositories under test use.
  final SupabaseClient client;

  /// Bypasses RLS: for seeding and cleanup.
  final SupabaseClient service;

  String get residentialId => demoResidentialId;
  String get unitId => demoUnitId;

  /// Rows (table -> ids) to delete on [dispose], in insertion order.
  final _tracked = <MapEntry<String, String>>[];

  static Future<TestResident> create() async {
    final service = newServiceClient();
    final suffix = Random().nextInt(1 << 32).toRadixString(36);
    final email = 'test-resident-$suffix@gates.test';
    const password = 'test-password-123';
    final created = await service.auth.admin.createUser(
      AdminUserAttributes(email: email, password: password, emailConfirm: true),
    );
    final userId = created.user!.id;
    await service.from('unit_members').insert({
      'unit_id': demoUnitId,
      'residential_id': demoResidentialId,
      'user_id': userId,
    });
    final client = newAnonClient();
    await client.auth.signInWithPassword(email: email, password: password);
    return TestResident._(
      userId: userId,
      email: email,
      client: client,
      service: service,
    );
  }

  /// Remember a row created during the test so it is deleted afterwards.
  void track(String table, String id) => _tracked.add(MapEntry(table, id));

  Future<void> dispose() async {
    for (final row in _tracked.reversed) {
      try {
        await service.from(row.key).delete().eq('id', row.value);
      } catch (_) {
        // Best effort: a dependent row may already be gone.
      }
    }
    try {
      await service.from('unit_members').delete().eq('user_id', userId);
      await service.auth.admin.deleteUser(userId);
    } catch (_) {}
    await client.auth.signOut();
    await client.dispose();
    await service.dispose();
  }
}

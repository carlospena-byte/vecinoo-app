import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/local_supabase.dart';

/// Far-future date so test visits never collide with real data.
final farFuture = DateTime(2098, 6, 15);

/// Seeds a visitor row via the service client (bypasses RLS) and tracks it.
Future<String> seedVisitor(
  TestResident resident, {
  String visitType = 'delivery',
  String status = 'scheduled',
  String name = 'Test: seeded visitor',
}) async {
  final row = await resident.service
      .from('visitors')
      .insert({
        'residential_id': resident.residentialId,
        'unit_id': resident.unitId,
        'invited_by': resident.userId,
        'name': name,
        'visit_type': visitType,
        'status': status,
        'valid_from': farFuture.toUtc().toIso8601String(),
        'valid_until': farFuture
            .add(const Duration(days: 1))
            .toUtc()
            .toIso8601String(),
      })
      .select()
      .single();
  final id = row['id'] as String;
  resident.track('visitors', id);
  return id;
}

Future<Map<String, dynamic>> readVisitor(SupabaseClient service, String id) =>
    service.from('visitors').select().eq('id', id).single();

Future<Map<String, dynamic>> readVisitorByName(
  SupabaseClient service,
  TestResident resident,
  String name,
) async {
  final row = await service
      .from('visitors')
      .select()
      .eq('unit_id', resident.unitId)
      .eq('invited_by', resident.userId)
      .eq('name', name)
      .single();
  resident.track('visitors', row['id'] as String);
  return row;
}

Uint8List fakePng() => Uint8List.fromList(List.filled(32, 7));

/// Runs SQL inside the local Supabase Postgres container. Needed only where
/// the service_role has no table grant (`providers`: gates-admin migration
/// 20261014000000 grants just `authenticated`). Returns null when docker or
/// the container is unavailable.
String? localPsql(String sql) {
  try {
    final r = Process.runSync('docker', [
      'exec',
      'supabase_db_gates-admin',
      'psql',
      '-U',
      'postgres',
      '-tAc',
      sql,
    ]);
    return r.exitCode == 0 ? r.stdout.toString().trim() : null;
  } catch (_) {
    return null;
  }
}

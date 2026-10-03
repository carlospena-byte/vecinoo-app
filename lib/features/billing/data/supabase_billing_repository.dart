import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../domain/billing_repository.dart';
import '../domain/installment.dart';

/// Supabase-backed [BillingRepository]. RLS only exposes the rows of units
/// the signed-in user belongs to; the explicit `unit_id` filter picks which.
class SupabaseBillingRepository implements BillingRepository {
  SupabaseBillingRepository(this._client);

  final SupabaseClient _client;

  static const _view = 'v_charge_installments';

  List<Installment> _parse(Object rows) => [
    for (final row in rows as List)
      Installment.fromMap(row as Map<String, dynamic>),
  ];

  @override
  Future<List<Installment>> fetchOpen(String unitId) => guardFailure(() async {
    final rows = await _client
        .from(_view)
        .select()
        .eq('unit_id', unitId)
        .inFilter('status', ['pending', 'partial'])
        .order('due_date', ascending: true);
    return _parse(rows);
  });

  @override
  Future<List<Installment>> fetchHistory(
    String unitId, {
    required int limit,
    int offset = 0,
  }) => guardFailure(() async {
    final rows = await _client
        .from(_view)
        .select()
        .eq('unit_id', unitId)
        .inFilter('status', ['paid', 'cancelled'])
        .order('period', ascending: false)
        .order('due_date', ascending: false)
        .range(offset, offset + limit - 1);
    return _parse(rows);
  });
}

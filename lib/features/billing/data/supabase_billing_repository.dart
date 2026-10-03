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

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

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
    required DateRange range,
    required int limit,
    int offset = 0,
  }) => guardFailure(() async {
    final from = _date(range.start);
    // Exclusive upper bound, so a timestamp late on the last day still counts.
    final to = _date(
      DateTime(range.end.year, range.end.month, range.end.day + 1),
    );
    // Cancelled installments have no payment date: they fall back to the due
    // date so they stay filterable.
    final rows = await _client
        .from(_view)
        .select()
        .eq('unit_id', unitId)
        .inFilter('status', ['paid', 'cancelled'])
        .or(
          'and(paid_at.gte.$from,paid_at.lt.$to),'
          'and(paid_at.is.null,due_date.gte.$from,due_date.lt.$to)',
        )
        .order('paid_at', ascending: false, nullsFirst: false)
        .order('due_date', ascending: false)
        .range(offset, offset + limit - 1);
    return _parse(rows);
  });
}

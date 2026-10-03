import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/paging/paged_notifier.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../data/supabase_billing_repository.dart';
import '../domain/billing_repository.dart';
import '../domain/installment.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return SupabaseBillingRepository(ref.watch(supabaseClientProvider));
});

/// Open (pending / partial) installments of a unit.
final openInstallmentsProvider =
    FutureProvider.family<List<Installment>, String>(
      (ref, unitId) => ref.watch(billingRepositoryProvider).fetchOpen(unitId),
    );

/// What the unit owes right now; null while loading or if it failed.
final billingBalanceProvider =
    Provider.family<AsyncValue<BillingBalance>, String>(
      (ref, unitId) => ref
          .watch(openInstallmentsProvider(unitId))
          .whenData(BillingBalance.fromOpen),
    );

/// Pages through the settled installments (the payment history).
class BillingHistoryController extends PagedNotifier<Installment> {
  BillingHistoryController(this.unitId);

  final String unitId;

  @override
  Future<List<Installment>> fetchPage({
    required int offset,
    required int limit,
  }) => ref
      .read(billingRepositoryProvider)
      .fetchHistory(unitId, limit: limit, offset: offset);
}

final billingHistoryProvider = NotifierProvider.autoDispose
    .family<BillingHistoryController, PagedState<Installment>, String>(
      BillingHistoryController.new,
    );

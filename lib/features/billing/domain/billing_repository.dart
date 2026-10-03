import 'installment.dart';

/// What the billing feature needs from storage. Implementations throw
/// `Failure`s (see core/error/failure.dart), never raw backend exceptions.
abstract interface class BillingRepository {
  /// Every installment of this unit still pending or partially paid,
  /// oldest due date first.
  Future<List<Installment>> fetchOpen(String unitId);

  /// One page of this unit's settled (paid or cancelled) installments,
  /// newest period first. A page shorter than [limit] is the last one.
  Future<List<Installment>> fetchHistory(
    String unitId, {
    required int limit,
    int offset = 0,
  });
}

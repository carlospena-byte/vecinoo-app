import 'installment.dart';

/// An inclusive span of calendar days (time of day is ignored).
class DateRange {
  const DateRange(this.start, this.end);

  /// The whole month [day] falls in.
  factory DateRange.monthOf(DateTime day) => DateRange(
    DateTime(day.year, day.month),
    DateTime(day.year, day.month + 1, 0),
  );

  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// What the billing feature needs from storage. Implementations throw
/// `Failure`s (see core/error/failure.dart), never raw backend exceptions.
abstract interface class BillingRepository {
  /// Every installment of this unit still pending or partially paid,
  /// oldest due date first.
  Future<List<Installment>> fetchOpen(String unitId);

  /// One page of this unit's settled (paid or cancelled) installments whose
  /// payment date (due date for cancelled ones) falls in [range], most
  /// recent payment first. A page shorter than [limit] is the last one.
  Future<List<Installment>> fetchHistory(
    String unitId, {
    required DateRange range,
    required int limit,
    int offset = 0,
  });
}

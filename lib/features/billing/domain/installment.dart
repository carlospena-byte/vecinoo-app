enum InstallmentStatus { pending, partial, paid, cancelled }

InstallmentStatus installmentStatusFromString(String value) {
  switch (value) {
    case 'partial':
      return InstallmentStatus.partial;
    case 'paid':
      return InstallmentStatus.paid;
    case 'cancelled':
      return InstallmentStatus.cancelled;
    default:
      return InstallmentStatus.pending;
  }
}

/// One monthly charge billed to a unit (a row of `v_charge_installments`).
/// Late fee, balance and overdue-ness are computed by the backend.
class Installment {
  const Installment({
    required this.id,
    required this.chargeName,
    required this.period,
    required this.dueDate,
    required this.status,
    required this.baseAmount,
    required this.lateFee,
    required this.totalDue,
    required this.paidAmount,
    required this.balance,
    required this.isOverdue,
    required this.daysOverdue,
    this.paidAt,
    this.isBooking = false,
  });

  final String id;
  final String chargeName;

  /// First day of the billed month.
  final DateTime period;
  final DateTime dueDate;
  final InstallmentStatus status;
  final double baseAmount;
  final double lateFee;
  final double totalDue;
  final double paidAmount;

  /// What is still owed, late fee included.
  final double balance;
  final bool isOverdue;
  final int daysOverdue;
  final DateTime? paidAt;

  /// Born from an amenity reservation rather than a recurring charge.
  final bool isBooking;

  bool get isOpen =>
      status == InstallmentStatus.pending ||
      status == InstallmentStatus.partial;

  factory Installment.fromMap(Map<String, dynamic> map) {
    double num_(String key) => (map[key] as num?)?.toDouble() ?? 0;
    // `date` columns arrive as "2026-10-10": parse as local calendar days.
    DateTime day(String value) => DateTime.parse(value);
    final paidAt = map['paid_at'] as String?;
    return Installment(
      id: map['id'] as String,
      chargeName: map['charge_name'] as String,
      period: day(map['period'] as String),
      dueDate: day(map['due_date'] as String),
      status: installmentStatusFromString(map['status'] as String),
      baseAmount: num_('base_amount'),
      lateFee: num_('late_fee'),
      totalDue: num_('total_due'),
      paidAmount: num_('paid_amount'),
      balance: num_('balance'),
      isOverdue: map['is_overdue'] as bool? ?? false,
      daysOverdue: (map['days_overdue'] as num?)?.toInt() ?? 0,
      paidAt: paidAt == null ? null : day(paidAt),
      isBooking: map['source'] == 'booking',
    );
  }
}

/// What a unit currently owes: the open installments added up.
class BillingBalance {
  const BillingBalance({
    required this.total,
    required this.overdue,
    required this.overdueCount,
    required this.openCount,
  });

  static const zero = BillingBalance(
    total: 0,
    overdue: 0,
    overdueCount: 0,
    openCount: 0,
  );

  /// Everything still owed (overdue + not yet due).
  final double total;
  final double overdue;
  final int overdueCount;
  final int openCount;

  bool get isSettled => openCount == 0;
  bool get hasOverdue => overdueCount > 0;

  factory BillingBalance.fromOpen(Iterable<Installment> open) {
    var total = 0.0;
    var overdue = 0.0;
    var overdueCount = 0;
    var count = 0;
    for (final i in open) {
      if (!i.isOpen) continue;
      count++;
      total += i.balance;
      if (i.isOverdue) {
        overdue += i.balance;
        overdueCount++;
      }
    }
    return BillingBalance(
      total: total,
      overdue: overdue,
      overdueCount: overdueCount,
      openCount: count,
    );
  }
}

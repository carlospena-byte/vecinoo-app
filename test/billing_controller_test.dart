import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/features/billing/domain/billing_repository.dart';
import 'package:gates_app/features/billing/domain/installment.dart';
import 'package:gates_app/features/billing/presentation/billing_controller.dart';

Installment makeInstallment({
  String id = 'i',
  InstallmentStatus status = InstallmentStatus.pending,
  double balance = 100,
  bool overdue = false,
}) => Installment(
  id: id,
  chargeName: 'Mantenimiento',
  period: DateTime(2026, 10),
  dueDate: DateTime(2026, 10, 10),
  status: status,
  baseAmount: balance,
  lateFee: 0,
  totalDue: balance,
  paidAmount: 0,
  balance: balance,
  isOverdue: overdue,
  daysOverdue: overdue ? 3 : 0,
);

class _FakeBillingRepository implements BillingRepository {
  List<Installment> open = [];
  int historyCount = 0;
  final offsets = <int>[];

  @override
  Future<List<Installment>> fetchOpen(String unitId) async => open;

  @override
  Future<List<Installment>> fetchHistory(
    String unitId, {
    required int limit,
    int offset = 0,
  }) async {
    offsets.add(offset);
    final end = (offset + limit).clamp(0, historyCount);
    return [
      for (var i = offset; i < end; i++)
        makeInstallment(id: 'h$i', status: InstallmentStatus.paid),
    ];
  }
}

void main() {
  test('source decides whether an installment is a booking', () {
    Map<String, dynamic> row(String source) => {
      'id': 'i',
      'charge_name': 'Alberca',
      'period': '2026-10-01',
      'due_date': '2026-10-05',
      'status': 'pending',
      'source': source,
      'balance': 80,
    };
    expect(Installment.fromMap(row('booking')).isBooking, isTrue);
    expect(Installment.fromMap(row('charge')).isBooking, isFalse);
  });

  test('balance adds up open installments and flags the overdue ones', () {
    final balance = BillingBalance.fromOpen([
      makeInstallment(balance: 300, overdue: true),
      makeInstallment(balance: 50.5, status: InstallmentStatus.partial),
      makeInstallment(status: InstallmentStatus.paid, balance: 0),
    ]);
    expect(balance.total, 350.5);
    expect(balance.overdue, 300);
    expect(balance.overdueCount, 1);
    expect(balance.openCount, 2);
    expect(balance.isSettled, isFalse);
    expect(BillingBalance.fromOpen(const []).isSettled, isTrue);
  });

  test('billingBalanceProvider sums what the repository returns', () async {
    final repo = _FakeBillingRepository()
      ..open = [makeInstallment(balance: 120), makeInstallment(balance: 80)];
    final container = ProviderContainer(
      overrides: [billingRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container.read(openInstallmentsProvider('u').future);
    expect(container.read(billingBalanceProvider('u')).value?.total, 200);
  });

  test('history loads 10, then the rest, then stops', () async {
    final repo = _FakeBillingRepository()..historyCount = 12;
    final container = ProviderContainer(
      overrides: [billingRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(billingHistoryProvider('u'), (_, _) {});
    final notifier = container.read(billingHistoryProvider('u').notifier);
    await Future<void>.delayed(Duration.zero);
    expect(sub.read().items, hasLength(10));
    await notifier.loadMore();
    expect(sub.read().items, hasLength(12));
    expect(sub.read().hasMore, isFalse);
    expect(repo.offsets, [0, 10]);
  });
}

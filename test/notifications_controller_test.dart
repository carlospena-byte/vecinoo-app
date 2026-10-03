import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/core/notifications/push_navigation.dart';
import 'package:gates_app/features/notifications/presentation/notifications_controller.dart';

import 'widgets/notifications/fakes.dart';

void main() {
  late FakeNotificationsRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeNotificationsRepository()
      ..notifications = [
        for (var i = 0; i < 25; i++) makeNotification(id: 'n$i'),
      ];
    container = ProviderContainer(overrides: notificationOverrides(repo));
    addTearDown(container.dispose);
  });

  test('loads 20, then the rest, then stops', () async {
    final sub = container.listen(notificationsPagingProvider, (_, _) {});
    final notifier = container.read(notificationsPagingProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    expect(sub.read().items, hasLength(20));
    expect(sub.read().hasMore, isTrue);

    await notifier.loadMore();
    expect(sub.read().items, hasLength(25));
    expect(sub.read().hasMore, isFalse);
    expect(repo.offsets, [0, 20]);
  });

  test('markRead updates the list at once and persists', () async {
    final sub = container.listen(notificationsPagingProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    await container.read(notificationsPagingProvider.notifier).markRead('n1');
    expect(sub.read().items.firstWhere((n) => n.id == 'n1').isRead, isTrue);
    expect(sub.read().items.firstWhere((n) => n.id == 'n2').isRead, isFalse);
    expect(repo.markedRead, ['n1']);
  });

  test('markRead keeps the local change when storage fails', () async {
    final sub = container.listen(notificationsPagingProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    repo.markError = const NetworkFailure();
    await container.read(notificationsPagingProvider.notifier).markRead('n1');
    expect(sub.read().items.firstWhere((n) => n.id == 'n1').isRead, isTrue);
  });

  test('markAllRead marks every loaded item', () async {
    final sub = container.listen(notificationsPagingProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    final ok = await container
        .read(notificationsPagingProvider.notifier)
        .markAllRead();
    expect(ok, isTrue);
    expect(repo.markAllCalls, 1);
    expect(sub.read().items.every((n) => n.isRead), isTrue);
  });

  test('markAllRead leaves the list alone when storage fails', () async {
    final sub = container.listen(notificationsPagingProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    repo.markError = const NetworkFailure();
    final ok = await container
        .read(notificationsPagingProvider.notifier)
        .markAllRead();
    expect(ok, isFalse);
    expect(sub.read().items.any((n) => n.isRead), isFalse);
  });

  test('inbox types resolve to the same routes as pushes', () {
    expect(notificationRoute({'type': 'payment'}), '/billing');
    expect(notificationRoute({'type': 'charge'}), '/billing');
    expect(notificationRoute({'type': 'booking'}), '/amenities');
    expect(
      notificationRoute({'type': 'incident', 'incident_id': 'i1'}),
      '/incidents/i1',
    );
    expect(
      notificationRoute({'type': 'visitor_checkin', 'visitorId': 'v1'}),
      '/visits/v1',
    );
    expect(notificationRoute({'type': 'incident'}), isNull);
  });
}

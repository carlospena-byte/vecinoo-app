import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/bulletins/presentation/bulletins_controller.dart';

import 'widgets/bulletins/fakes.dart';

void main() {
  late FakeBulletinsRepository repo;
  late FakeBulletinReadsRepository reads;
  late ProviderContainer container;

  setUp(() {
    repo = FakeBulletinsRepository()
      ..bulletins = [for (var i = 0; i < 12; i++) makeBulletin(id: 'b$i')];
    reads = FakeBulletinReadsRepository({'b0'});
    container = ProviderContainer(overrides: bulletinOverrides(repo, reads));
    addTearDown(container.dispose);
  });

  test('loads 10, then the rest, then stops', () async {
    final sub = container.listen(bulletinsPagingProvider('r'), (_, _) {});
    final notifier = container.read(bulletinsPagingProvider('r').notifier);
    await Future<void>.delayed(Duration.zero);
    expect(sub.read().items, hasLength(10));
    expect(sub.read().hasMore, isTrue);

    await notifier.loadMore();
    expect(sub.read().items, hasLength(12));
    expect(sub.read().hasMore, isFalse);

    await notifier.loadMore();
    expect(repo.offsets, [0, 10]);
  });

  test('a failure keeps the items and the next call retries', () async {
    final sub = container.listen(bulletinsPagingProvider('r'), (_, _) {});
    final notifier = container.read(bulletinsPagingProvider('r').notifier);
    await Future<void>.delayed(Duration.zero);
    repo.listError = const NetworkFailure();
    await notifier.loadMore();
    expect(sub.read().failure, isA<NetworkFailure>());
    expect(sub.read().items, hasLength(10));

    repo.listError = null;
    await notifier.loadMore();
    expect(sub.read().failure, isNull);
    expect(sub.read().items, hasLength(12));
  });

  test('refresh restarts from the first page', () async {
    final sub = container.listen(bulletinsPagingProvider('r'), (_, _) {});
    final notifier = container.read(bulletinsPagingProvider('r').notifier);
    await Future<void>.delayed(Duration.zero);
    await notifier.refresh();
    expect(sub.read().items, hasLength(10));
    expect(repo.offsets, [0, 0]);
  });

  test('read ids load from storage and markRead persists', () async {
    final sub = container.listen(bulletinReadIdsProvider('r'), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(sub.read(), {'b0'});

    await container.read(bulletinReadIdsProvider('r').notifier).markRead('b3');
    expect(sub.read(), {'b0', 'b3'});
    expect(reads.read, {'b0', 'b3'});
  });
}

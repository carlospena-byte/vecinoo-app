@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/visits/data/providers_catalog_repository.dart';
import 'package:gates_app/features/visits/domain/visit.dart';

import 'support/local_supabase.dart';
import 'visits_support.dart';

void main() {
  late TestResident resident;
  late ProvidersCatalogRepository repository;

  setUp(() async {
    resident = await TestResident.create();
    repository = ProvidersCatalogRepository(resident.client);
  });

  tearDown(() => resident.dispose());

  // service_role has no grant on `providers`, so extras are seeded through
  // psql in the DB container and removed by name in tearDown.
  final seeded = <String>[];
  bool canSeed() => localPsql('select 1') != null;

  String seed(
    String name,
    String kind, {
    bool active = true,
    String? residentialId,
  }) {
    final out = localPsql(
      "insert into providers (residential_id, name, kind, is_active) values "
      "(${residentialId == null ? 'null' : "'$residentialId'"}, '$name', '$kind', $active) returning id",
    );
    final id = out!.split('\n').first;
    seeded.add(id);
    return id;
  }

  tearDown(() {
    for (final id in seeded) {
      localPsql(
        "delete from providers where id = '$id' and name like 'Test:%'",
      );
    }
    seeded.clear();
  });

  test(
    'returns active providers of the kind for this residential, sorted by name',
    () async {
      final b = seed(
        'Test: B repartidor',
        'delivery',
        residentialId: resident.residentialId,
      );
      final a = seed(
        'Test: A repartidor',
        'delivery',
        residentialId: resident.residentialId,
      );
      final inactive = seed(
        'Test: inactivo',
        'delivery',
        active: false,
        residentialId: resident.residentialId,
      );
      final otherKind = seed(
        'Test: paquetería',
        'paqueteria',
        residentialId: resident.residentialId,
      );

      final items = await repository.fetchCatalog(
        residentialId: resident.residentialId,
        kind: ProviderKind.delivery,
      );
      final ids = items.map((i) => i.id).toList();
      expect(ids, containsAllInOrder([a, b]));
      expect(ids, isNot(contains(inactive)));
      expect(ids, isNot(contains(otherKind)));
      expect(items.every((i) => i.kind == ProviderKind.delivery), isTrue);
      final names = items.map((i) => i.name).toList();
      expect([...names]..sort(), names);
      final mine = items.firstWhere((i) => i.id == a);
      expect(mine.residentialId, resident.residentialId);
      expect(mine.name, 'Test: A repartidor');

      final paq = await repository.fetchCatalog(
        residentialId: resident.residentialId,
        kind: ProviderKind.paqueteria,
      );
      expect(paq.map((i) => i.id), contains(otherKind));
    },
    skip:
        localSupabaseSkipReason ??
        (canSeed() ? null : 'docker/psql unavailable'),
    tags: 'integration',
  );

  test(
    'includes platform-wide entries but not another residential\'s extras',
    () async {
      final global = seed('Test: global proveedor', 'proveedor');
      final own = seed(
        'Test: propio proveedor',
        'proveedor',
        residentialId: resident.residentialId,
      );

      final items = await repository.fetchCatalog(
        residentialId: resident.residentialId,
        kind: ProviderKind.proveedor,
      );
      final byId = {for (final i in items) i.id: i};
      expect(byId[global]!.residentialId, isNull);
      expect(byId[global]!.logoUrl, isNull);
      expect(byId.containsKey(own), isTrue);

      // Asking for a different residential filters out this one's extras.
      final other = await repository.fetchCatalog(
        residentialId: '00000000-0000-0000-0000-000000000001',
        kind: ProviderKind.proveedor,
      );
      final otherIds = other.map((i) => i.id);
      expect(otherIds, contains(global));
      expect(otherIds, isNot(contains(own)));
    },
    skip:
        localSupabaseSkipReason ??
        (canSeed() ? null : 'docker/psql unavailable'),
    tags: 'integration',
  );

  test(
    'a malformed residential id surfaces as a typed Failure',
    () async {
      await expectLater(
        repository.fetchCatalog(
          residentialId: 'not-a-uuid',
          kind: ProviderKind.delivery,
        ),
        throwsA(isA<ServerFailure>()),
      );
    },
    skip: localSupabaseSkipReason,
    tags: 'integration',
  );
}

@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/profile/data/supabase_profile_repository.dart';

import 'support/local_supabase.dart';

void main() {
  late TestResident resident;
  late SupabaseProfileRepository repository;

  setUp(() async {
    resident = await TestResident.create();
    repository = SupabaseProfileRepository(resident.client);
  });

  tearDown(() => resident.dispose());

  test(
    'fetchMine returns the resident profile',
    () async {
      final profile = await repository.fetchMine();
      expect(profile.userId, resident.userId);
      expect(profile.email, resident.email);
      expect(profile.isComplete, isFalse);
    },
    skip: localSupabaseSkipReason,
    tags: 'integration',
  );

  test(
    'updateMine writes each optional field independently',
    () async {
      await repository.updateMine(firstName: 'Test: Ana');
      var p = await repository.fetchMine();
      expect(p.firstName, 'Test: Ana');
      expect(p.lastName, isNull);

      await repository.updateMine(lastName: 'Test: Perez');
      p = await repository.fetchMine();
      expect(p.firstName, 'Test: Ana');
      expect(p.lastName, 'Test: Perez');
      expect(p.isComplete, isTrue);

      await repository.updateMine(phone: '+50412345678');
      p = await repository.fetchMine();
      expect(p.phone, '+50412345678');
      expect(p.lastName, 'Test: Perez');

      await repository.updateMine(
        firstName: 'Test: Beto',
        lastName: 'Test: Gomez',
        phone: '+50400000000',
      );
      p = await repository.fetchMine();
      expect(p.displayName, 'Test: Beto Test: Gomez');
      expect(p.phone, '+50400000000');
    },
    skip: localSupabaseSkipReason,
    tags: 'integration',
  );

  test(
    'updateMine with no fields is a no-op',
    () async {
      await repository.updateMine();
      expect((await repository.fetchMine()).firstName, isNull);
    },
    skip: localSupabaseSkipReason,
    tags: 'integration',
  );

  test(
    'without a signed-in user every call throws AuthFailure',
    () async {
      final anon = newAnonClient();
      addTearDown(anon.dispose);
      final anonRepo = SupabaseProfileRepository(anon);
      await expectLater(anonRepo.fetchMine(), throwsA(isA<AuthFailure>()));
      await expectLater(
        anonRepo.updateMine(firstName: 'x'),
        throwsA(isA<AuthFailure>()),
      );
    },
    skip: localSupabaseSkipReason,
    tags: 'integration',
  );
}

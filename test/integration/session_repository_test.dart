@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/session/data/supabase_session_repository.dart';
import 'package:gates_app/features/session/domain/invitation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_support.dart';
import 'support/local_supabase.dart';

void main() {
  late SupabaseClient service;
  final invitationIds = <String>[];

  setUp(() => service = newServiceClient());

  tearDown(() async {
    for (final id in invitationIds) {
      try {
        await service.from('unit_invitations').delete().eq('id', id);
      } catch (_) {}
    }
    invitationIds.clear();
    await service.dispose();
  });

  test(
    'checkEmailLoginStatus reports unknown, invited and active',
    () async {
      final anon = newAnonClient();
      addTearDown(anon.dispose);
      final repository = SupabaseSessionRepository(anon);

      final unknownEmail = uniqueTestEmail('test-unknown');
      expect(
        await repository.checkEmailLoginStatus(unknownEmail),
        EmailLoginStatus.unknown,
      );

      final invitedEmail = uniqueTestEmail('test-invited');
      final inv = await insertInvitation(service, email: invitedEmail);
      invitationIds.add(inv.id);
      expect(
        await repository.checkEmailLoginStatus(invitedEmail),
        EmailLoginStatus.invited,
      );

      final resident = await TestResident.create();
      addTearDown(resident.dispose);
      expect(
        await repository.checkEmailLoginStatus(resident.email),
        EmailLoginStatus.active,
      );
    },
    skip: localSupabaseSkipReason,
    tags: 'integration',
  );

  test(
    'validateInvitation returns a preview for a valid code, null otherwise',
    () async {
      final anon = newAnonClient();
      addTearDown(anon.dispose);
      final repository = SupabaseSessionRepository(anon);

      final email = uniqueTestEmail('test-validate');
      final inv = await insertInvitation(service, email: email);
      invitationIds.add(inv.id);

      final preview = await repository.validateInvitation(code: inv.code);
      expect(preview, isNotNull);
      expect(preview!.email, email);
      expect(preview.unitName, isNotEmpty);
      expect(preview.residentialName, isNotEmpty);

      expect(await repository.validateInvitation(code: '000000x'), isNull);

      final expired = await insertInvitation(
        service,
        email: uniqueTestEmail('test-expired'),
        expiresIn: const Duration(hours: -1),
      );
      invitationIds.add(expired.id);
      expect(await repository.validateInvitation(code: expired.code), isNull);

      final revoked = await insertInvitation(
        service,
        email: uniqueTestEmail('test-revoked'),
        status: 'revoked',
      );
      invitationIds.add(revoked.id);
      expect(await repository.validateInvitation(code: revoked.code), isNull);
    },
    skip: localSupabaseSkipReason,
    tags: 'integration',
  );

  test(
    'fetchMyMemberships returns the unit with its residential',
    () async {
      final resident = await TestResident.create();
      addTearDown(resident.dispose);
      final repository = SupabaseSessionRepository(resident.client);

      final memberships = await repository.fetchMyMemberships();
      expect(memberships, hasLength(1));
      expect(memberships.single.unitId, resident.unitId);
      expect(memberships.single.residentialId, resident.residentialId);
      expect(memberships.single.label, contains('·'));
    },
    skip: localSupabaseSkipReason,
    tags: 'integration',
  );

  test(
    'fetchMyMemberships without a session throws AuthFailure',
    () async {
      final anon = newAnonClient();
      addTearDown(anon.dispose);
      await expectLater(
        SupabaseSessionRepository(anon).fetchMyMemberships(),
        throwsA(isA<AuthFailure>()),
      );
    },
    skip: localSupabaseSkipReason,
    tags: 'integration',
  );

  test(
    'acceptInvitation links the user to the unit and burns the code',
    () async {
      final user = await BareUser.create();
      addTearDown(user.dispose);
      final repository = SupabaseSessionRepository(user.client);
      expect(await repository.fetchMyMemberships(), isEmpty);

      final inv = await insertInvitation(service, email: user.email);
      invitationIds.add(inv.id);

      expect(await repository.acceptInvitation(inv.code), isTrue);
      final memberships = await repository.fetchMyMemberships();
      expect(memberships.map((m) => m.unitId), [demoUnitId]);

      final row = await service
          .from('unit_invitations')
          .select('status')
          .eq('id', inv.id)
          .single();
      expect(row['status'], 'accepted');

      // Already used.
      expect(await repository.acceptInvitation(inv.code), isFalse);
    },
    skip: localSupabaseSkipReason,
    tags: 'integration',
  );

  test(
    'acceptInvitation returns false for an unknown or expired code',
    () async {
      final user = await BareUser.create();
      addTearDown(user.dispose);
      final repository = SupabaseSessionRepository(user.client);

      expect(await repository.acceptInvitation('nope-nope'), isFalse);

      final expired = await insertInvitation(
        service,
        email: user.email,
        expiresIn: const Duration(hours: -1),
      );
      invitationIds.add(expired.id);
      expect(await repository.acceptInvitation(expired.code), isFalse);
      expect(await repository.fetchMyMemberships(), isEmpty);
    },
    skip: localSupabaseSkipReason,
    tags: 'integration',
  );
}

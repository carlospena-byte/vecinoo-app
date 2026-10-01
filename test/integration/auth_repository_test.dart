@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/auth/data/supabase_auth_repository.dart';
import 'package:gates_app/features/auth/domain/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_support.dart';
import 'support/local_supabase.dart';

void main() {
  late SupabaseClient client;
  late SupabaseClient service;
  late SupabaseAuthRepository repository;
  final emails = <String>[];

  setUp(() {
    client = newPkceAnonClient();
    service = newServiceClient();
    repository = SupabaseAuthRepository(client);
  });

  tearDown(() async {
    for (final email in emails) {
      await deleteUserByEmail(service, email);
    }
    emails.clear();
    await client.auth.signOut();
    await client.dispose();
    await service.dispose();
  });

  test(
    'email OTP: send, rate limit, wrong code, right code, sign out',
    () async {
      final email = uniqueTestEmail('test-otp');
      emails.add(email);
      expect(repository.currentUser, isNull);

      final events = <SignedInUser?>[];
      final sub = repository.userChanges.listen(events.add);
      addTearDown(sub.cancel);

      expect(await repository.sendEmailOtp(email), OtpSendOutcome.sent);
      // Supabase throttles repeated sends to the same address.
      expect(await repository.sendEmailOtp(email), OtpSendOutcome.rateLimited);

      final code = await readOtpFor(email);
      final wrong = code == '000000' ? '111111' : '000000';
      expect(
        await repository.verifyEmailOtp(email: email, token: wrong),
        OtpVerifyOutcome.invalidCode,
      );
      expect(repository.currentUser, isNull);

      expect(
        await repository.verifyEmailOtp(email: email, token: code),
        OtpVerifyOutcome.verified,
      );
      expect(repository.currentUser?.email, email);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(
        events.whereType<SignedInUser>().map((u) => u.email),
        contains(email),
      );

      await repository.signOut();
      expect(repository.currentUser, isNull);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(events.last, isNull);
    },
    skip: localSupabaseSkipReason,
    tags: 'integration',
  );

  test(
    'phone OTP surfaces typed outcomes or failures, never raw exceptions',
    () async {
      Object? sendError;
      try {
        final outcome = await repository.sendPhoneOtp('+50499990000');
        expect(outcome, isA<OtpSendOutcome>());
      } catch (e) {
        sendError = e;
      }
      if (sendError != null) expect(sendError, isA<Failure>());

      try {
        final outcome = await repository.verifyPhoneOtp(
          phone: '+50499990000',
          token: '000000',
        );
        expect(outcome, OtpVerifyOutcome.invalidCode);
      } catch (e) {
        expect(e, isA<Failure>());
      }
    },
    skip: localSupabaseSkipReason,
    tags: 'integration',
  );
}

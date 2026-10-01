import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/auth/domain/auth_repository.dart';
import 'package:gates_app/features/auth/presentation/auth_controller.dart';
import 'package:gates_app/features/auth/presentation/login_controller.dart';
import 'package:gates_app/features/auth/presentation/otp_verify_controller.dart';
import 'package:gates_app/features/auth/presentation/register_controller.dart';
import 'package:gates_app/features/session/domain/invitation.dart';
import 'package:gates_app/features/session/domain/membership.dart';
import 'package:gates_app/features/session/domain/session_repository.dart';
import 'package:gates_app/features/session/presentation/session_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuth implements AuthRepository {
  OtpSendOutcome sendOutcome = OtpSendOutcome.sent;
  OtpVerifyOutcome verifyOutcome = OtpVerifyOutcome.verified;
  Object? error;
  final calls = <String>[];

  @override
  SignedInUser? get currentUser => null;

  @override
  Stream<SignedInUser?> get userChanges => const Stream.empty();

  @override
  Future<OtpSendOutcome> sendEmailOtp(String email) async {
    calls.add('sendEmail:$email');
    if (error != null) throw error!;
    return sendOutcome;
  }

  @override
  Future<OtpSendOutcome> sendPhoneOtp(String phone) async {
    calls.add('sendPhone:$phone');
    if (error != null) throw error!;
    return sendOutcome;
  }

  @override
  Future<OtpVerifyOutcome> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    calls.add('verifyEmail:$email:$token');
    if (error != null) throw error!;
    return verifyOutcome;
  }

  @override
  Future<OtpVerifyOutcome> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    calls.add('verifyPhone:$phone:$token');
    if (error != null) throw error!;
    return verifyOutcome;
  }

  @override
  Future<void> signOut() async {}
}

class _FakeSession implements SessionRepository {
  EmailLoginStatus status = EmailLoginStatus.active;
  InvitationPreview? invitation = const InvitationPreview(
    unitName: 'A-204',
    residentialName: 'Los Olivos',
    email: 'ana@example.com',
    fullName: 'Ana',
  );
  List<Membership> memberships = const [];
  Object? error;

  @override
  Future<EmailLoginStatus> checkEmailLoginStatus(String email) async {
    if (error != null) throw error!;
    return status;
  }

  @override
  Future<InvitationPreview?> validateInvitation({required String code}) async {
    if (error != null) throw error!;
    return invitation;
  }

  @override
  Future<List<Membership>> fetchMyMemberships() async => memberships;

  @override
  Future<bool> acceptInvitation(String code) async => true;
}

ProviderContainer _container(_FakeAuth auth, _FakeSession session) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      sessionRepositoryProvider.overrideWithValue(session),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

const _args = OtpVerifyArgs(
  identifier: 'ana@example.com',
  channel: OtpChannel.email,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('login', () {
    test('sends the code and emits LoginCodeSent', () async {
      final auth = _FakeAuth();
      final container = _container(auth, _FakeSession());
      container.listen(loginControllerProvider, (_, _) {});
      final controller = container.read(loginControllerProvider.notifier);
      final events = <LoginEvent>[];
      controller.events.listen(events.add);

      await controller.submit('ana@example.com');
      await Future<void>.delayed(Duration.zero);

      expect(auth.calls, ['sendEmail:ana@example.com']);
      expect(events.single, isA<LoginCodeSent>());
      expect(container.read(loginControllerProvider).error, isNull);
    });

    test('invited and unknown emails never get a code', () async {
      final auth = _FakeAuth();
      final session = _FakeSession()..status = EmailLoginStatus.invited;
      final container = _container(auth, session);
      container.listen(loginControllerProvider, (_, _) {});
      final controller = container.read(loginControllerProvider.notifier);

      await controller.submit('a@b.c');
      expect(
        container.read(loginControllerProvider).error,
        isA<InvitationPending>(),
      );

      session.status = EmailLoginStatus.unknown;
      await controller.submit('a@b.c');
      expect(
        container.read(loginControllerProvider).error,
        isA<EmailUnknown>(),
      );
      expect(auth.calls, isEmpty);
    });

    test('network errors become a typed SendCodeFailed', () async {
      final auth = _FakeAuth()..error = TimeoutException('slow');
      final container = _container(auth, _FakeSession());
      container.listen(loginControllerProvider, (_, _) {});

      await container.read(loginControllerProvider.notifier).submit('a@b.c');

      final error = container.read(loginControllerProvider).error;
      expect(error, isA<SendCodeFailed>());
      expect((error! as SendCodeFailed).failure, isA<NetworkFailure>());
      expect(container.read(loginControllerProvider).isSubmitting, isFalse);
    });

    test('a rate limit fails without detail', () async {
      final auth = _FakeAuth()..sendOutcome = OtpSendOutcome.rateLimited;
      final container = _container(auth, _FakeSession());
      container.listen(loginControllerProvider, (_, _) {});

      await container.read(loginControllerProvider.notifier).submit('a@b.c');

      final error = container.read(loginControllerProvider).error;
      expect((error! as SendCodeFailed).failure, isNull);
    });
  });

  group('otp verify', () {
    test('rejects an incomplete code without calling the backend', () async {
      final auth = _FakeAuth();
      final container = _container(auth, _FakeSession());
      container.listen(otpVerifyControllerProvider(_args), (_, _) {});

      await container
          .read(otpVerifyControllerProvider(_args).notifier)
          .verify('123');

      expect(
        container.read(otpVerifyControllerProvider(_args)).error,
        isA<OtpIncomplete>(),
      );
      expect(auth.calls, isEmpty);
    });

    test('an invalid code is a typed outcome, not a failure', () async {
      final auth = _FakeAuth()..verifyOutcome = OtpVerifyOutcome.invalidCode;
      final container = _container(auth, _FakeSession());
      container.listen(otpVerifyControllerProvider(_args), (_, _) {});

      await container
          .read(otpVerifyControllerProvider(_args).notifier)
          .verify('123456');

      final state = container.read(otpVerifyControllerProvider(_args));
      expect(state.error, isA<OtpInvalidCode>());
      expect(state.isSubmitting, isFalse);
      expect(auth.calls, ['verifyEmail:ana@example.com:123456']);
    });

    test('connectivity errors surface the failure', () async {
      final auth = _FakeAuth()..error = TimeoutException('slow');
      final container = _container(auth, _FakeSession());
      container.listen(otpVerifyControllerProvider(_args), (_, _) {});

      await container
          .read(otpVerifyControllerProvider(_args).notifier)
          .verify('123456');

      final error = container.read(otpVerifyControllerProvider(_args)).error;
      expect((error! as OtpVerifyFailed).failure, isA<NetworkFailure>());
    });

    test('phone channel verifies through the phone endpoint', () async {
      const phoneArgs = OtpVerifyArgs(
        identifier: '+50412345678',
        channel: OtpChannel.phone,
      );
      final auth = _FakeAuth();
      final container = _container(auth, _FakeSession());
      container.listen(otpVerifyControllerProvider(phoneArgs), (_, _) {});

      await container
          .read(otpVerifyControllerProvider(phoneArgs).notifier)
          .verify('123456');

      expect(auth.calls, ['verifyPhone:+50412345678:123456']);
    });

    test('offers biometric setup once for a linked resident', () async {
      final auth = _FakeAuth();
      final session = _FakeSession()
        ..memberships = const [
          Membership(
            residentialId: 'r',
            residentialName: 'Los Olivos',
            unitId: 'u',
            unitName: 'A-204',
          ),
        ];
      final container = _container(auth, session);
      container.listen(otpVerifyControllerProvider(_args), (_, _) {});
      final controller = container.read(
        otpVerifyControllerProvider(_args).notifier,
      );
      final events = <OtpEvent>[];
      controller.events.listen(events.add);

      await controller.verify('123456');
      await controller.verify('123456');
      await Future<void>.delayed(Duration.zero);

      expect(events.whereType<ShowBiometricSetup>(), hasLength(1));
    });

    testWidgets('resend is locked until the cooldown ends', (tester) async {
      final auth = _FakeAuth();
      final container = _container(auth, _FakeSession());
      container.listen(otpVerifyControllerProvider(_args), (_, _) {});
      final controller = container.read(
        otpVerifyControllerProvider(_args).notifier,
      );
      final events = <OtpEvent>[];
      controller.events.listen(events.add);

      await controller.resend();
      expect(auth.calls, isEmpty);

      await tester.pump(const Duration(seconds: otpResendCooldownSeconds));
      expect(
        container.read(otpVerifyControllerProvider(_args)).cooldownRemaining,
        0,
      );

      await controller.resend();
      await tester.pump();
      expect(auth.calls, ['sendEmail:ana@example.com']);
      expect(events.single, isA<ResendSucceeded>());
      expect(
        container.read(otpVerifyControllerProvider(_args)).cooldownRemaining,
        otpResendCooldownSeconds,
      );
      container.dispose();
    });

    testWidgets('a failed resend restarts the cooldown', (tester) async {
      final auth = _FakeAuth()..sendOutcome = OtpSendOutcome.rateLimited;
      final container = _container(auth, _FakeSession());
      container.listen(otpVerifyControllerProvider(_args), (_, _) {});
      final controller = container.read(
        otpVerifyControllerProvider(_args).notifier,
      );
      final events = <OtpEvent>[];
      controller.events.listen(events.add);

      await tester.pump(const Duration(seconds: otpResendCooldownSeconds));
      await controller.resend();
      await tester.pump();

      expect(events.single, isA<ResendFailed>());
      expect((events.single as ResendFailed).failure, isNull);
      expect(
        container.read(otpVerifyControllerProvider(_args)).cooldownRemaining,
        otpResendCooldownSeconds,
      );
      container.dispose();
    });
  });

  group('register', () {
    test('valid invitation sends the code, saves it and navigates', () async {
      final auth = _FakeAuth();
      final container = _container(auth, _FakeSession());
      container.listen(registerControllerProvider, (_, _) {});
      final controller = container.read(registerControllerProvider.notifier);
      final events = <RegisterEvent>[];
      controller.events.listen(events.add);

      await controller.acceptInvitation('123456');
      await Future<void>.delayed(Duration.zero);

      expect(auth.calls, ['sendEmail:ana@example.com']);
      final sent = events.single as RegisterCodeSent;
      expect(sent.args.registration?.unitName, 'A-204');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pendingInvitationCodePrefsKey), '123456');
    });

    test('an invalid invitation is rejected without sending a code', () async {
      final auth = _FakeAuth();
      final session = _FakeSession()..invitation = null;
      final container = _container(auth, session);
      container.listen(registerControllerProvider, (_, _) {});

      await container
          .read(registerControllerProvider.notifier)
          .acceptInvitation('123456');

      expect(
        container.read(registerControllerProvider).error,
        isA<InvitationRejected>(),
      );
      expect(auth.calls, isEmpty);
    });

    test('short codes are incomplete; backend errors are typed', () async {
      final session = _FakeSession();
      final container = _container(_FakeAuth(), session);
      container.listen(registerControllerProvider, (_, _) {});
      final controller = container.read(registerControllerProvider.notifier);

      await controller.acceptInvitation('12');
      expect(
        container.read(registerControllerProvider).error,
        isA<InvitationIncomplete>(),
      );

      session.error = const ServerFailure();
      await controller.acceptInvitation('123456');
      final error = container.read(registerControllerProvider).error;
      expect((error! as RegisterFailed).failure, isA<ServerFailure>());
    });
  });
}

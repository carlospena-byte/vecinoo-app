import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/core/widgets/otp_code_field.dart';
import 'package:gates_app/features/auth/domain/auth_repository.dart';
import 'package:gates_app/features/auth/presentation/auth_controller.dart';
import 'package:gates_app/features/auth/presentation/biometric_setup_screen.dart';
import 'package:gates_app/features/auth/presentation/login_screen.dart';
import 'package:gates_app/features/auth/presentation/otp_verify_screen.dart';
import 'package:gates_app/features/auth/presentation/register_screen.dart';
import 'package:gates_app/features/session/domain/invitation.dart';
import 'package:gates_app/features/session/presentation/session_controller.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fonts.dart';
import '../../helpers/pump_app.dart';
import '_fakes.dart';

final _es = AppLocalizationsEs();

void main() {
  setUpAll(loadManrope);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('LoginScreen', () {
    late FakeAuthRepo auth;
    late FakeSessionRepo session;
    late List<String> visited;
    Object? extra;

    setUp(() {
      auth = FakeAuthRepo();
      session = FakeSessionRepo();
      visited = [];
      extra = null;
    });

    Future<void> pump(WidgetTester tester, {ThemeMode? mode}) => pumpApp(
      tester,
      const LoginScreen(),
      mode: mode ?? ThemeMode.light,
      visited: visited,
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        sessionRepositoryProvider.overrideWithValue(session),
      ],
      routes: {
        '/verify-otp': (state) {
          extra = state.extra;
          return const Text('otp-route');
        },
        '/register': (_) => const Text('register-route'),
      },
    );

    testWidgets('renders title, field and actions (dark too)', (tester) async {
      await pump(tester, mode: ThemeMode.dark);
      expect(find.text(_es.authLoginTitle), findsOneWidget);
      expect(find.text(_es.authEmailLabel), findsOneWidget);
      expect(find.text(_es.commonContinue), findsOneWidget);
      expect(find.text(_es.authHaveInvitationCode), findsOneWidget);
    });

    testWidgets('invalid email shows the validation message', (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextField), 'nope');
      await tester.tap(find.text(_es.commonContinue));
      await tester.pumpAndSettle();
      expect(find.text(_es.authEmailInvalid), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('valid email sends a code and opens verify-otp', (
      tester,
    ) async {
      await pump(tester);
      await tester.enterText(find.byType(TextField), ' ana@example.com ');
      await tester.tap(find.text(_es.commonContinue));
      await tester.pumpAndSettle();
      expect(auth.calls, ['sendEmail:ana@example.com']);
      expect(visited, ['/verify-otp']);
      final args = extra as OtpVerifyArgs;
      expect(args.identifier, 'ana@example.com');
      expect(args.channel, OtpChannel.email);
    });

    testWidgets('shows a spinner and disables actions while submitting', (
      tester,
    ) async {
      auth.sendGate = Completer<OtpSendOutcome>();
      await pump(tester);
      await tester.enterText(find.byType(TextField), 'ana@example.com');
      await tester.tap(find.text(_es.commonContinue));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      auth.sendGate!.complete(OtpSendOutcome.sent);
      await tester.pumpAndSettle();
    });

    testWidgets('invited email points at the invitation flow', (tester) async {
      session.status = EmailLoginStatus.invited;
      await pump(tester);
      await tester.enterText(find.byType(TextField), 'a@b.c');
      await tester.tap(find.text(_es.commonContinue));
      await tester.pumpAndSettle();
      expect(find.text(_es.authInvitationPending), findsOneWidget);
      expect(visited, isEmpty);
    });

    testWidgets('unknown email is rejected', (tester) async {
      session.status = EmailLoginStatus.unknown;
      await pump(tester);
      await tester.enterText(find.byType(TextField), 'a@b.c');
      await tester.tap(find.text(_es.commonContinue));
      await tester.pumpAndSettle();
      expect(find.text(_es.authEmailUnknown), findsOneWidget);
    });

    testWidgets('rate limit shows the generic send failure', (tester) async {
      auth.sendOutcome = OtpSendOutcome.rateLimited;
      await pump(tester);
      await tester.enterText(find.byType(TextField), 'a@b.c');
      await tester.tap(find.text(_es.commonContinue));
      await tester.pumpAndSettle();
      expect(find.text(_es.authSendCodeFailed), findsOneWidget);
    });

    testWidgets('network failure adds its detail', (tester) async {
      session.error = const NetworkFailure();
      await pump(tester);
      await tester.enterText(find.byType(TextField), 'a@b.c');
      await tester.tap(find.text(_es.commonContinue));
      await tester.pumpAndSettle();
      expect(
        find.text('${_es.commonErrorNetwork} ${_es.authSendCodeFailed}'),
        findsOneWidget,
      );
    });

    testWidgets('invitation code link opens the register route', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text(_es.authHaveInvitationCode));
      await tester.pumpAndSettle();
      expect(visited, ['/register']);
    });
  });

  group('RegisterScreen', () {
    late FakeAuthRepo auth;
    late FakeSessionRepo session;
    late List<String> visited;
    Object? extra;

    setUp(() {
      auth = FakeAuthRepo();
      session = FakeSessionRepo();
      visited = [];
      extra = null;
    });

    Future<void> pump(WidgetTester tester, {ThemeMode? mode}) => pumpApp(
      tester,
      const RegisterScreen(),
      mode: mode ?? ThemeMode.light,
      visited: visited,
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        sessionRepositoryProvider.overrideWithValue(session),
      ],
      routes: {
        '/verify-otp': (state) {
          extra = state.extra;
          return const Text('otp-route');
        },
      },
    );

    testWidgets('the continue button is disabled until the code is full', (
      tester,
    ) async {
      await pump(tester);
      final button = find.widgetWithText(
        ElevatedButton,
        _es.authAcceptInvitation,
      );
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
      await tester.enterText(find.byType(TextField), '12');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
    });

    testWidgets('a full valid code is accepted automatically', (tester) async {
      await pump(tester, mode: ThemeMode.dark);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle();
      expect(session.calls, ['validate:123456']);
      expect(auth.calls, ['sendEmail:ana@example.com']);
      expect(visited, ['/verify-otp']);
      final args = extra as OtpVerifyArgs;
      expect(args.registration?.unitName, 'A-204');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pending_invitation_code'), '123456');
    });

    testWidgets('an invalid code shows the rejection', (tester) async {
      session.invitation = null;
      await pump(tester);
      await tester.enterText(find.byType(TextField), '999999');
      await tester.pumpAndSettle();
      expect(find.text(_es.authInvitationInvalid), findsOneWidget);
      expect(visited, isEmpty);
    });

    testWidgets('server failures show detail plus the invalid copy', (
      tester,
    ) async {
      session.error = const ServerFailure();
      await pump(tester);
      await tester.enterText(find.byType(TextField), '999999');
      await tester.pumpAndSettle();
      expect(
        find.text('${_es.commonErrorServer} ${_es.authInvitationInvalid}'),
        findsOneWidget,
      );
    });

    testWidgets('tapping the button after an error retries', (tester) async {
      session.invitation = null;
      await pump(tester);
      await tester.enterText(find.byType(TextField), '999999');
      await tester.pumpAndSettle();
      session.invitation = const InvitationPreview(
        unitName: 'B-1',
        residentialName: 'Pinos',
        email: 'x@y.z',
      );
      await tester.tap(find.text(_es.authAcceptInvitation));
      await tester.pumpAndSettle();
      expect(visited, ['/verify-otp']);
    });

    testWidgets('contact support shows an info toast', (tester) async {
      await pump(tester);
      await tester.tap(find.text(_es.authNoInvitationContactSupport));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(_es.authSupportTitle), findsOneWidget);
      expect(find.text(_es.authSupportMessage), findsOneWidget);
    });
  });

  group('OtpVerifyScreen', () {
    late FakeAuthRepo auth;
    late FakeSessionRepo session;
    late List<String> visited;

    setUp(() {
      auth = FakeAuthRepo();
      session = FakeSessionRepo();
      visited = [];
    });

    Future<void> pump(
      WidgetTester tester,
      OtpVerifyArgs args, {
      ThemeMode mode = ThemeMode.light,
    }) => pumpApp(
      tester,
      OtpVerifyScreen(args: args),
      mode: mode,
      visited: visited,
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        sessionRepositoryProvider.overrideWithValue(session),
      ],
      routes: {'/setup-biometrics': (_) => const Text('bio-route')},
    );

    Future<void> dispose(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
    }

    const emailArgs = OtpVerifyArgs(
      identifier: 'ana@example.com',
      channel: OtpChannel.email,
    );

    testWidgets('email variant shows identifier and a resend countdown', (
      tester,
    ) async {
      await pump(tester, emailArgs);
      expect(find.text(_es.authCheckEmail), findsOneWidget);
      expect(find.text('ana@example.com'), findsOneWidget);
      expect(find.text(_es.authResendIn(60)), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(find.text(_es.authResendIn(55)), findsOneWidget);
      await dispose(tester);
    });

    testWidgets('phone variant with registration context (dark)', (
      tester,
    ) async {
      await pump(
        tester,
        const OtpVerifyArgs(
          identifier: '+50499999999',
          channel: OtpChannel.phone,
          registration: RegistrationContext(
            residentialName: 'Los Olivos',
            unitName: 'A-204',
            fullName: 'Ana',
          ),
        ),
        mode: ThemeMode.dark,
      );
      expect(find.text(_es.authCheckPhone), findsOneWidget);
      expect(find.text(_es.authInvitationValidated), findsOneWidget);
      expect(find.text('A-204 · Los Olivos'), findsOneWidget);
      expect(find.text(_es.authResidentName('Ana')), findsOneWidget);
      await dispose(tester);
    });

    testWidgets('registration context without a name hides the name line', (
      tester,
    ) async {
      await pump(
        tester,
        const OtpVerifyArgs(
          identifier: 'a@b.c',
          channel: OtpChannel.email,
          registration: RegistrationContext(
            residentialName: 'Los Olivos',
            unitName: 'A-204',
          ),
        ),
      );
      expect(
        find.textContaining(_es.authResidentName('').trim()),
        findsNothing,
      );
      await dispose(tester);
    });

    testWidgets('the verify button with a short code shows an error', (
      tester,
    ) async {
      await pump(tester, emailArgs);
      await tester.enterText(find.byType(TextField), '123');
      await tester.tap(find.text(_es.authVerifyAndSignIn));
      await tester.pump();
      expect(find.text(_es.authEnterDigits(6)), findsOneWidget);
      expect(auth.calls, isEmpty);
      await dispose(tester);
    });

    testWidgets('a wrong code shows the invalid-code error', (tester) async {
      auth.verifyOutcome = OtpVerifyOutcome.invalidCode;
      await pump(tester, emailArgs);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      expect(auth.calls, ['verifyEmail:ana@example.com:123456']);
      expect(find.text(_es.authOtpWrongOrExpired), findsOneWidget);
      await dispose(tester);
    });

    testWidgets('a failure shows its detail', (tester) async {
      auth.error = const NetworkFailure();
      await pump(tester, emailArgs);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      await tester.pump();
      expect(
        find.text('${_es.commonErrorNetwork} ${_es.authOtpWrongOrExpired}'),
        findsOneWidget,
      );
      await dispose(tester);
    });

    testWidgets('phone verification uses the phone endpoint', (tester) async {
      await pump(
        tester,
        const OtpVerifyArgs(identifier: '+504999', channel: OtpChannel.phone),
      );
      await tester.enterText(find.byType(TextField), '654321');
      await tester.pump();
      await tester.pump();
      expect(auth.calls, ['verifyPhone:+504999:654321']);
      await dispose(tester);
    });

    testWidgets('verified with a linked unit offers biometric setup', (
      tester,
    ) async {
      session.memberships = [testMembership];
      await pump(tester, emailArgs);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(visited, ['/setup-biometrics']);
      await dispose(tester);
    });

    testWidgets('verified without memberships does not offer biometrics', (
      tester,
    ) async {
      await pump(tester, emailArgs);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(visited, isEmpty);
      await dispose(tester);
    });

    testWidgets('resend is enabled after the countdown and toasts success', (
      tester,
    ) async {
      await pump(tester, emailArgs);
      await tester.pump(const Duration(seconds: 61));
      expect(find.text(_es.authResend), findsOneWidget);
      await tester.tap(find.text(_es.authResend));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(auth.calls, ['sendEmail:ana@example.com']);
      expect(find.text(_es.authOtpResentTitle), findsOneWidget);
      expect(find.text(_es.authResendIn(60)), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await dispose(tester);
    });

    testWidgets('a rate-limited resend toasts an error and restarts cooldown', (
      tester,
    ) async {
      auth.sendOutcome = OtpSendOutcome.rateLimited;
      await pump(tester, emailArgs);
      await tester.pump(const Duration(seconds: 61));
      await tester.tap(find.text(_es.authResend));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(_es.authOtpResendFailedTitle), findsOneWidget);
      expect(find.text(_es.authOtpResendFailedMessage), findsOneWidget);
      expect(find.text(_es.authResendIn(60)), findsOneWidget);
      await dispose(tester);
    });

    testWidgets('a failed resend shows the failure detail', (tester) async {
      auth.error = const NetworkFailure();
      await pump(tester, emailArgs);
      await tester.pump(const Duration(seconds: 61));
      await tester.tap(find.text(_es.authResend));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.text(
          '${_es.commonErrorNetwork} ${_es.authOtpResendFailedMessage}',
        ),
        findsOneWidget,
      );
      await dispose(tester);
    });

    testWidgets('exposes the OTP field', (tester) async {
      await pump(tester, emailArgs);
      expect(find.byType(OtpCodeField), findsOneWidget);
      await dispose(tester);
    });
  });

  group('BiometricSetupScreen', () {
    testWidgets('both buttons continue into the app', (tester) async {
      final visited = <String>[];
      for (final label in [_es.authBiometricSetup, _es.authBiometricSkip]) {
        visited.clear();
        await pumpApp(
          tester,
          const BiometricSetupScreen(),
          visited: visited,
          routes: {'/': (_) => const Text('x')},
        );
        expect(find.text(_es.authBiometricTitle), findsOneWidget);
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('dark theme smoke', (tester) async {
      await pumpApp(tester, const BiometricSetupScreen(), mode: ThemeMode.dark);
      expect(find.text(_es.authBiometricBody), findsOneWidget);
    });
  });
}

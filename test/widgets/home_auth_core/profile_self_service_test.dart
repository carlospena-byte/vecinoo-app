import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:gates_app/core/app_info.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/core/security/biometric_lock_gate.dart';
import 'package:gates_app/core/security/biometric_service.dart';
import 'package:gates_app/core/widgets/otp_code_field.dart';
import 'package:gates_app/features/auth/domain/auth_repository.dart';
import 'package:gates_app/features/auth/presentation/auth_controller.dart';
import 'package:gates_app/features/incidents/presentation/photo_picker.dart';
import 'package:gates_app/features/profile/domain/profile.dart';
import 'package:gates_app/features/profile/presentation/avatar_picker.dart';
import 'package:gates_app/features/profile/presentation/profile_controller.dart';
import 'package:gates_app/features/profile/presentation/profile_screen.dart';
import 'package:gates_app/features/session/presentation/session_controller.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fonts.dart';
import '../../helpers/pump_app.dart';
import '_fakes.dart';

final _es = AppLocalizationsEs();

class _FakeAvatarPicker implements AvatarPicker {
  @override
  Future<XFile?> pick(PhotoSource source) async => XFile.fromData(
    Uint8List.fromList([1, 2, 3]),
    name: 'me.png',
    mimeType: 'image/png',
  );
}

void main() {
  setUpAll(loadManrope);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late FakeAuthRepo auth;
  late FakeSessionRepo session;
  late FakeProfileRepo profiles;
  late FakeBiometricAuthenticator biometrics;

  setUp(() {
    auth = FakeAuthRepo(user: const SignedInUser(id: 'u1'));
    session = FakeSessionRepo()..memberships = [testMembership];
    profiles = FakeProfileRepo();
    biometrics = FakeBiometricAuthenticator();
  });

  Future<void> pump(WidgetTester tester) => pumpApp(
    tester,
    const ProfileScreen(),
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      sessionRepositoryProvider.overrideWithValue(session),
      profileRepositoryProvider.overrideWithValue(profiles),
      biometricAuthenticatorProvider.overrideWithValue(biometrics),
      avatarPickerProvider.overrideWithValue(_FakeAvatarPicker()),
      appVersionProvider.overrideWith((ref) async => '1.0.0'),
    ],
  );

  group('ProfileScreen self-service', () {
    testWidgets('shows the app version', (tester) async {
      await pump(tester);
      await tester.scrollUntilVisible(
        find.textContaining('V 1.0.0'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('V 1.0.0'), findsOneWidget);
    });

    testWidgets('editing the name saves first and last name', (tester) async {
      await pump(tester);
      await tester.tap(find.text(_es.profileEditName));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Maria');
      await tester.enterText(fields.at(1), 'Lopez');
      await tester.tap(find.text(_es.profileSave));
      await tester.pumpAndSettle();
      expect(profiles.calls, ['update:Maria:Lopez:null']);
      expect(find.text(_es.profileSaved), findsOneWidget);
    });

    testWidgets('an empty name is rejected', (tester) async {
      await pump(tester);
      await tester.tap(find.text(_es.profileEditName));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '');
      await tester.tap(find.text(_es.profileSave));
      await tester.pumpAndSettle();
      expect(profiles.calls, isEmpty);
      expect(find.text(_es.profileFieldRequired), findsOneWidget);
    });

    testWidgets('a failed save keeps the sheet open with the cause', (
      tester,
    ) async {
      profiles.updateError = const NetworkFailure();
      await pump(tester);
      await tester.tap(find.text(_es.profileEditName));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_es.profileSave));
      await tester.pumpAndSettle();
      expect(
        find.text('${_es.commonErrorNetwork} ${_es.profileSaveFailed}'),
        findsOneWidget,
      );
    });

    testWidgets('changing the photo uploads the picked image', (tester) async {
      await pump(tester);
      await tester.tap(find.byIcon(TablerIcons.camera));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_es.profilePhotoGallery));
      await tester.pumpAndSettle();
      expect(profiles.calls, ['avatar:3:png']);
      expect(find.text(_es.profilePhotoUpdated), findsOneWidget);
    });
  });

  group('change email', () {
    Future<void> openSheet(WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.text('ana@example.com'));
      await tester.pumpAndSettle();
    }

    testWidgets('sends a code to the new address, then confirms it', (
      tester,
    ) async {
      await openSheet(tester);
      await tester.enterText(find.byType(TextField), 'nuevo@example.com');
      await tester.tap(find.text(_es.profileEmailSendCode));
      await tester.pumpAndSettle();
      expect(profiles.calls, ['requestEmail:nuevo@example.com']);
      expect(
        find.text(_es.profileEmailCodeSentTo('nuevo@example.com')),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle();
      // The field confirms as soon as the sixth digit lands.
      expect(profiles.calls.last, 'confirmEmail:nuevo@example.com:123456');
      expect(find.text(_es.profileEmailChanged), findsOneWidget);
    });

    testWidgets('rejects an invalid or unchanged address without sending', (
      tester,
    ) async {
      await openSheet(tester);
      await tester.enterText(find.byType(TextField), 'nope');
      await tester.tap(find.text(_es.profileEmailSendCode));
      await tester.pumpAndSettle();
      expect(find.text(_es.profileEmailInvalid), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'ANA@example.com');
      await tester.tap(find.text(_es.profileEmailSendCode));
      await tester.pumpAndSettle();
      expect(find.text(_es.profileEmailSame), findsOneWidget);
      expect(profiles.calls, isEmpty);
    });

    testWidgets('a wrong code keeps the email unchanged', (tester) async {
      profiles.emailVerifyOutcome = OtpVerifyOutcome.invalidCode;
      await openSheet(tester);
      await tester.enterText(find.byType(TextField), 'nuevo@example.com');
      await tester.tap(find.text(_es.profileEmailSendCode));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '000000');
      await tester.pumpAndSettle();
      expect(find.text(_es.profileEmailInvalidCode), findsOneWidget);
      expect(find.byType(OtpCodeField), findsOneWidget);
      expect(find.text(_es.profileEmailChanged), findsNothing);
    });

    testWidgets('rate limiting is explained', (tester) async {
      profiles.emailSendOutcome = OtpSendOutcome.rateLimited;
      await openSheet(tester);
      await tester.enterText(find.byType(TextField), 'nuevo@example.com');
      await tester.tap(find.text(_es.profileEmailSendCode));
      await tester.pumpAndSettle();
      expect(find.text(_es.profileEmailRateLimited), findsOneWidget);
    });

    testWidgets('use another email returns to the first step', (tester) async {
      await openSheet(tester);
      await tester.enterText(find.byType(TextField), 'nuevo@example.com');
      await tester.tap(find.text(_es.profileEmailSendCode));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_es.profileEmailUseOther));
      await tester.pumpAndSettle();
      expect(find.text(_es.profileEmailSendCode), findsOneWidget);
    });
  });

  group('biometrics', () {
    Future<void> showSwitch(WidgetTester tester) async {
      await pump(tester);
      await tester.scrollUntilVisible(
        find.text(_es.profileBiometricTitle),
        200,
      );
    }

    testWidgets('the switch turns it on after the system prompt', (
      tester,
    ) async {
      await showSwitch(tester);
      await tester.tap(find.text(_es.profileBiometricTitle));
      await tester.pumpAndSettle();
      expect(biometrics.prompts, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(biometricEnabledPrefsKey), isTrue);

      await tester.tap(find.text(_es.profileBiometricTitle));
      await tester.pumpAndSettle();
      expect(prefs.getBool(biometricEnabledPrefsKey), isFalse);
    });

    testWidgets('stays off when the prompt fails', (tester) async {
      biometrics.passes = false;
      await showSwitch(tester);
      await tester.tap(find.text(_es.profileBiometricTitle));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(_es.profileBiometricCancelled), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(biometricEnabledPrefsKey), isNull);
    });

    testWidgets('warns when the device has no biometrics', (tester) async {
      biometrics.available = false;
      await showSwitch(tester);
      await tester.tap(find.text(_es.profileBiometricTitle));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(_es.profileBiometricUnavailable), findsOneWidget);
      expect(biometrics.prompts, 0);
    });
  });

  group('account deletion', () {
    Future<void> tapDelete(WidgetTester tester) async {
      await tester.scrollUntilVisible(find.text(_es.profileDeleteAccount), 200);
      await tester.tap(find.text(_es.profileDeleteAccount));
      await tester.pumpAndSettle();
    }

    testWidgets('asks for confirmation, then schedules the deletion', (
      tester,
    ) async {
      await pump(tester);
      await tapDelete(tester);
      expect(find.text(_es.profileDeleteTitle), findsOneWidget);
      expect(profiles.calls, isEmpty);
      await tester.tap(find.text(_es.profileDeleteConfirm));
      await tester.pumpAndSettle();
      expect(profiles.calls, ['requestDeletion']);
      expect(find.text(_es.profileDeleteRequested), findsOneWidget);
    });

    testWidgets('cancelling the sheet requests nothing', (tester) async {
      await pump(tester);
      await tapDelete(tester);
      await tester.tap(find.text(_es.commonCancel));
      await tester.pumpAndSettle();
      expect(profiles.calls, isEmpty);
    });

    testWidgets('a failed request toasts the cause', (tester) async {
      profiles.deletionError = const ServerFailure();
      await pump(tester);
      await tapDelete(tester);
      await tester.tap(find.text(_es.profileDeleteConfirm));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(_es.profileDeleteFailed), findsOneWidget);
      expect(find.text(_es.commonErrorServer), findsOneWidget);
    });

    testWidgets('a pending request shows the date and can be cancelled', (
      tester,
    ) async {
      profiles.profile = Profile(
        userId: 'u1',
        email: 'ana@example.com',
        firstName: 'Ana',
        lastName: 'Perez',
        deletionScheduledFor: DateTime(2027, 5, 31),
      );
      await pump(tester);
      expect(find.text(_es.profileDeletePendingTitle), findsOneWidget);
      expect(find.textContaining('31'), findsWidgets);
      expect(find.text(_es.profileDeleteAccount), findsNothing);
      await tester.tap(find.text(_es.profileDeleteCancel));
      await tester.pumpAndSettle();
      expect(profiles.calls, ['cancelDeletion']);
    });
  });

  group('BiometricLockGate', () {
    Future<void> pumpGate(WidgetTester tester, {bool enabled = true}) async {
      SharedPreferences.setMockInitialValues({
        if (enabled) biometricEnabledPrefsKey: true,
      });
      await pumpApp(
        tester,
        const BiometricLockGate(child: Text('app-content')),
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          biometricAuthenticatorProvider.overrideWithValue(biometrics),
        ],
      );
    }

    testWidgets('prompts at launch and unlocks when it passes', (tester) async {
      await pumpGate(tester);
      expect(biometrics.prompts, 1);
      expect(find.text('app-content'), findsOneWidget);
      expect(find.text(_es.lockTitle), findsNothing);
    });

    testWidgets('stays locked when the prompt fails, and can retry', (
      tester,
    ) async {
      biometrics.passes = false;
      await pumpGate(tester);
      expect(find.text(_es.lockTitle), findsOneWidget);
      biometrics.passes = true;
      await tester.tap(find.text(_es.lockUnlock));
      await tester.pumpAndSettle();
      expect(find.text(_es.lockTitle), findsNothing);
    });

    testWidgets('does nothing when biometrics are off', (tester) async {
      await pumpGate(tester, enabled: false);
      expect(biometrics.prompts, 0);
      expect(find.text(_es.lockTitle), findsNothing);
    });

    testWidgets('re-locks after the app goes to the background', (
      tester,
    ) async {
      await pumpGate(tester);
      biometrics.passes = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      // Frames are paused in the background; the lock shows on return.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(biometrics.prompts, 2);
      expect(find.text(_es.lockTitle), findsOneWidget);
    });

    testWidgets('removing biometrics from the device unlocks and disables', (
      tester,
    ) async {
      biometrics.available = false;
      await pumpGate(tester);
      expect(find.text(_es.lockTitle), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(biometricEnabledPrefsKey), isFalse);
    });
  });
}

import 'dart:async';
import 'dart:typed_data';

import 'package:gates_app/core/security/biometric_service.dart';
import 'package:gates_app/features/auth/domain/auth_repository.dart';
import 'package:gates_app/features/profile/domain/profile.dart';
import 'package:gates_app/features/profile/domain/profile_repository.dart';
import 'package:gates_app/features/session/domain/invitation.dart';
import 'package:gates_app/features/session/domain/membership.dart';
import 'package:gates_app/features/session/domain/session_repository.dart';

class FakeAuthRepo implements AuthRepository {
  FakeAuthRepo({this.user});

  SignedInUser? user;
  OtpSendOutcome sendOutcome = OtpSendOutcome.sent;
  OtpVerifyOutcome verifyOutcome = OtpVerifyOutcome.verified;
  Object? error;
  Object? signOutError;
  Completer<OtpSendOutcome>? sendGate;
  final calls = <String>[];
  final controller = StreamController<SignedInUser?>.broadcast();

  @override
  SignedInUser? get currentUser => user;

  @override
  Stream<SignedInUser?> get userChanges => controller.stream;

  @override
  Future<OtpSendOutcome> sendEmailOtp(String email) async {
    calls.add('sendEmail:$email');
    if (error != null) throw error!;
    if (sendGate != null) return sendGate!.future;
    return sendOutcome;
  }

  @override
  Future<OtpSendOutcome> sendPhoneOtp(String phone) async {
    calls.add('sendPhone:$phone');
    if (error != null) throw error!;
    if (sendGate != null) return sendGate!.future;
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
  Future<void> signOut() async {
    calls.add('signOut');
    if (signOutError != null) throw signOutError!;
    user = null;
    controller.add(null);
  }
}

class FakeSessionRepo implements SessionRepository {
  EmailLoginStatus status = EmailLoginStatus.active;
  InvitationPreview? invitation = const InvitationPreview(
    unitName: 'A-204',
    residentialName: 'Los Olivos',
    email: 'ana@example.com',
    fullName: 'Ana',
  );
  List<Membership> memberships = const [];
  bool acceptResult = true;
  Object? error;
  Object? acceptError;
  final calls = <String>[];

  @override
  Future<EmailLoginStatus> checkEmailLoginStatus(String email) async {
    calls.add('status:$email');
    if (error != null) throw error!;
    return status;
  }

  @override
  Future<InvitationPreview?> validateInvitation({required String code}) async {
    calls.add('validate:$code');
    if (error != null) throw error!;
    return invitation;
  }

  @override
  Future<List<Membership>> fetchMyMemberships() async {
    if (error != null) throw error!;
    return memberships;
  }

  @override
  Future<bool> acceptInvitation(String code) async {
    calls.add('accept:$code');
    if (acceptError != null) throw acceptError!;
    return acceptResult;
  }
}

class FakeProfileRepo implements ProfileRepository {
  FakeProfileRepo([this.profile]);

  Profile? profile;
  Object? error;
  int fetches = 0;

  @override
  Future<Profile> fetchMine() async {
    fetches++;
    if (error != null) throw error!;
    return profile ??
        const Profile(
          userId: 'u1',
          email: 'ana@example.com',
          firstName: 'Ana',
          lastName: 'Perez',
          phone: '+50499999999',
        );
  }

  final calls = <String>[];
  Object? updateError;
  Object? deletionError;
  OtpSendOutcome emailSendOutcome = OtpSendOutcome.sent;
  OtpVerifyOutcome emailVerifyOutcome = OtpVerifyOutcome.verified;
  Object? emailError;
  DateTime deletionDate = DateTime(2027, 5, 31);

  @override
  Future<void> updateMine({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    calls.add('update:$firstName:$lastName:$phone');
    if (updateError != null) throw updateError!;
  }

  @override
  Future<String> uploadAvatar(Uint8List bytes, String extension) async {
    calls.add('avatar:${bytes.length}:$extension');
    return 'https://example.com/avatar.$extension';
  }

  @override
  Future<OtpSendOutcome> requestEmailChange(String newEmail) async {
    calls.add('requestEmail:$newEmail');
    if (emailError != null) throw emailError!;
    return emailSendOutcome;
  }

  @override
  Future<OtpVerifyOutcome> confirmEmailChange({
    required String newEmail,
    required String token,
  }) async {
    calls.add('confirmEmail:$newEmail:$token');
    if (emailError != null) throw emailError!;
    return emailVerifyOutcome;
  }

  @override
  Future<DateTime> requestAccountDeletion() async {
    calls.add('requestDeletion');
    if (deletionError != null) throw deletionError!;
    return deletionDate;
  }

  @override
  Future<void> cancelAccountDeletion() async {
    calls.add('cancelDeletion');
    if (deletionError != null) throw deletionError!;
  }
}

class FakeBiometricAuthenticator implements BiometricAuthenticator {
  FakeBiometricAuthenticator({this.available = true, this.passes = true});

  bool available;
  bool passes;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return passes;
  }
}

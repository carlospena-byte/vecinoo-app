import 'dart:async';

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

  @override
  Future<void> updateMine({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {}
}

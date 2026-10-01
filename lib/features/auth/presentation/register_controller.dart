import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/failure.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/auth_repository.dart';
import 'auth_controller.dart';
import 'otp_verify_controller.dart';

/// SharedPreferences key for an already-validated invitation code, saved
/// right before we navigate to the OTP screen (there's no active session
/// yet — passwordless sign-in only completes once the code is verified)
/// — see pending_link_screen.dart, which redeems it after that happens.
const pendingInvitationCodePrefsKey = 'pending_invitation_code';

const invitationCodeLength = 6;

/// Why the invitation could not be accepted.
sealed class RegisterError {
  const RegisterError();
}

/// The code field doesn't hold a full invitation code yet.
class InvitationIncomplete extends RegisterError {
  const InvitationIncomplete();
}

/// The code is invalid, used or expired (or the sign-in code could not be
/// requested because of a rate limit).
class InvitationRejected extends RegisterError {
  const InvitationRejected();
}

/// Anything else (connectivity, server...).
class RegisterFailed extends RegisterError {
  const RegisterFailed(this.failure);
  final Failure failure;
}

class RegisterState {
  const RegisterState({this.isSubmitting = false, this.error});

  final bool isSubmitting;
  final RegisterError? error;
}

/// One-off notifications the screen turns into navigation.
sealed class RegisterEvent {
  const RegisterEvent();
}

/// The invitation is valid and the sign-in code went out: verify it.
class RegisterCodeSent extends RegisterEvent {
  const RegisterCodeSent(this.args);
  final OtpVerifyArgs args;
}

/// Validates an invitation code, then sends the sign-in code to the email
/// the invitation carries.
class RegisterController extends Notifier<RegisterState> {
  final _events = StreamController<RegisterEvent>.broadcast();
  bool _disposed = false;

  Stream<RegisterEvent> get events => _events.stream;

  @override
  RegisterState build() {
    ref.onDispose(() {
      _disposed = true;
      _events.close();
    });
    return const RegisterState();
  }

  Future<void> acceptInvitation(String rawCode) async {
    if (rawCode.length != invitationCodeLength) {
      state = const RegisterState(error: InvitationIncomplete());
      return;
    }
    state = const RegisterState(isSubmitting: true);
    final code = rawCode.trim();
    try {
      final invitation = await ref
          .read(sessionRepositoryProvider)
          .validateInvitation(code: code);
      if (_disposed) return;
      if (invitation == null) {
        state = const RegisterState(error: InvitationRejected());
        return;
      }
      final outcome = await ref
          .read(authRepositoryProvider)
          .sendEmailOtp(invitation.email);
      if (_disposed) return;
      if (outcome == OtpSendOutcome.rateLimited) {
        state = const RegisterState(error: InvitationRejected());
        return;
      }

      // No active session until the code is verified on the next screen,
      // so save the already-validated invitation code for
      // pending_link_screen.dart to redeem once sign-in actually completes.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(pendingInvitationCodePrefsKey, code);
      if (_disposed) return;

      state = const RegisterState();
      _events.add(
        RegisterCodeSent(
          OtpVerifyArgs(
            identifier: invitation.email,
            channel: OtpChannel.email,
            registration: RegistrationContext(
              residentialName: invitation.residentialName,
              unitName: invitation.unitName,
              fullName: invitation.fullName,
            ),
          ),
        ),
      );
    } catch (error) {
      if (_disposed) return;
      state = RegisterState(error: RegisterFailed(Failure.from(error)));
    }
  }
}

final registerControllerProvider =
    NotifierProvider.autoDispose<RegisterController, RegisterState>(
      RegisterController.new,
    );

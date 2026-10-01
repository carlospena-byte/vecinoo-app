import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../session/domain/invitation.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/auth_repository.dart';
import 'auth_controller.dart';

/// Why the login form can't continue; the screen maps it to copy.
sealed class LoginError {
  const LoginError();
}

/// An admin already invited this email but it hasn't been linked to a unit
/// yet — sending a sign-in code here would just create a disconnected
/// account instead of the "Valida tu código" flow that activates it.
class InvitationPending extends LoginError {
  const InvitationPending();
}

/// No auth account/profile matches this email, or no admin has invited it.
class EmailUnknown extends LoginError {
  const EmailUnknown();
}

/// The code could not be sent (connectivity, rate limit, server...).
class SendCodeFailed extends LoginError {
  const SendCodeFailed([this.failure]);

  /// Null when the cause is a rate limit (no useful extra detail).
  final Failure? failure;
}

class LoginState {
  const LoginState({this.isSubmitting = false, this.error});

  final bool isSubmitting;
  final LoginError? error;
}

/// One-off notifications the screen turns into navigation.
sealed class LoginEvent {
  const LoginEvent();
}

/// The sign-in code went out to [email]; continue to verification.
class LoginCodeSent extends LoginEvent {
  const LoginCodeSent(this.email);
  final String email;
}

/// Email sign-in: checks the invitation status of the address, then sends
/// the one-time code. The screen owns the text field and hands the email
/// in on submit.
class LoginController extends Notifier<LoginState> {
  final _events = StreamController<LoginEvent>.broadcast();
  bool _disposed = false;

  Stream<LoginEvent> get events => _events.stream;

  @override
  LoginState build() {
    ref.onDispose(() {
      _disposed = true;
      _events.close();
    });
    return const LoginState();
  }

  Future<void> submit(String email) async {
    state = const LoginState(isSubmitting: true);
    try {
      final status = await ref
          .read(sessionRepositoryProvider)
          .checkEmailLoginStatus(email);
      if (_disposed) return;
      switch (status) {
        case EmailLoginStatus.invited:
          state = const LoginState(error: InvitationPending());
          return;
        case EmailLoginStatus.unknown:
          state = const LoginState(error: EmailUnknown());
          return;
        case EmailLoginStatus.active:
          break;
      }
      final outcome = await ref
          .read(authRepositoryProvider)
          .sendEmailOtp(email);
      if (_disposed) return;
      if (outcome == OtpSendOutcome.rateLimited) {
        state = const LoginState(error: SendCodeFailed());
        return;
      }
      state = const LoginState();
      _events.add(LoginCodeSent(email));
    } catch (error) {
      if (_disposed) return;
      state = LoginState(error: SendCodeFailed(Failure.from(error)));
    }
  }
}

final loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, LoginState>(
      LoginController.new,
    );

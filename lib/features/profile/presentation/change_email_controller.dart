import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../auth/domain/auth_repository.dart';
import 'profile_controller.dart';

enum ChangeEmailStep { enterEmail, enterCode }

/// Why the current step could not move on.
enum ChangeEmailError {
  invalidEmail,
  sameEmail,
  incompleteCode,
  invalidCode,
  rateLimited,

  /// Connectivity / server problem; see [ChangeEmailState.failure].
  failed,
}

/// Minimum wait before another code can be requested.
const changeEmailResendCooldownSeconds = 60;

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class ChangeEmailState {
  const ChangeEmailState({
    this.step = ChangeEmailStep.enterEmail,
    this.newEmail = '',
    this.isBusy = false,
    this.cooldownRemaining = 0,
    this.error,
    this.failure,
    this.done = false,
  });

  final ChangeEmailStep step;

  /// The address the code was sent to (empty on the first step).
  final String newEmail;
  final bool isBusy;
  final int cooldownRemaining;
  final ChangeEmailError? error;
  final Failure? failure;

  /// The new email was confirmed; the sheet can close.
  final bool done;

  ChangeEmailState copyWith({
    ChangeEmailStep? step,
    String? newEmail,
    bool? isBusy,
    int? cooldownRemaining,
    Object? error = _keep,
    Object? failure = _keep,
    bool? done,
  }) => ChangeEmailState(
    step: step ?? this.step,
    newEmail: newEmail ?? this.newEmail,
    isBusy: isBusy ?? this.isBusy,
    cooldownRemaining: cooldownRemaining ?? this.cooldownRemaining,
    error: identical(error, _keep) ? this.error : error as ChangeEmailError?,
    failure: identical(failure, _keep) ? this.failure : failure as Failure?,
    done: done ?? this.done,
  );
}

const _keep = Object();

/// Two-step email change: a code goes to the new address, and the email only
/// changes once the resident types it in.
class ChangeEmailController extends Notifier<ChangeEmailState> {
  ChangeEmailController(this.currentEmail);

  final String? currentEmail;

  Timer? _cooldownTimer;
  bool _disposed = false;

  @override
  ChangeEmailState build() {
    ref.onDispose(() {
      _disposed = true;
      _cooldownTimer?.cancel();
    });
    return const ChangeEmailState();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    state = state.copyWith(cooldownRemaining: changeEmailResendCooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.cooldownRemaining - 1;
      state = state.copyWith(cooldownRemaining: remaining);
      if (remaining <= 0) timer.cancel();
    });
  }

  /// Sends the code to [email] and moves on to the code step.
  Future<void> sendCode(String email) async {
    final target = email.trim();
    if (!_emailPattern.hasMatch(target)) {
      state = state.copyWith(error: ChangeEmailError.invalidEmail);
      return;
    }
    if (target.toLowerCase() == currentEmail?.toLowerCase()) {
      state = state.copyWith(error: ChangeEmailError.sameEmail);
      return;
    }
    await _send(target, moveToCodeStep: true);
  }

  /// Sends a fresh code to the address already chosen.
  Future<void> resend() async {
    if (state.cooldownRemaining > 0 || state.isBusy) return;
    await _send(state.newEmail, moveToCodeStep: false);
  }

  Future<void> _send(String email, {required bool moveToCodeStep}) async {
    state = state.copyWith(isBusy: true, error: null, failure: null);
    try {
      final outcome = await ref
          .read(profileRepositoryProvider)
          .requestEmailChange(email);
      if (_disposed) return;
      if (outcome == OtpSendOutcome.rateLimited) {
        state = state.copyWith(
          isBusy: false,
          error: ChangeEmailError.rateLimited,
        );
        return;
      }
      state = state.copyWith(
        isBusy: false,
        newEmail: email,
        step: moveToCodeStep ? ChangeEmailStep.enterCode : state.step,
      );
      _startCooldown();
    } catch (error) {
      if (_disposed) return;
      state = state.copyWith(
        isBusy: false,
        error: ChangeEmailError.failed,
        failure: Failure.from(error),
      );
    }
  }

  /// Back to the email step to pick another address.
  void useOtherEmail() {
    _cooldownTimer?.cancel();
    state = const ChangeEmailState();
  }

  Future<void> confirm(String code) async {
    final token = code.trim();
    if (token.length != 6) {
      state = state.copyWith(error: ChangeEmailError.incompleteCode);
      return;
    }
    state = state.copyWith(isBusy: true, error: null, failure: null);
    try {
      final outcome = await ref
          .read(profileRepositoryProvider)
          .confirmEmailChange(newEmail: state.newEmail, token: token);
      if (_disposed) return;
      if (outcome == OtpVerifyOutcome.invalidCode) {
        state = state.copyWith(
          isBusy: false,
          error: ChangeEmailError.invalidCode,
        );
        return;
      }
      ref.invalidate(myProfileProvider);
      state = state.copyWith(isBusy: false, done: true);
    } catch (error) {
      if (_disposed) return;
      state = state.copyWith(
        isBusy: false,
        error: ChangeEmailError.failed,
        failure: Failure.from(error),
      );
    }
  }
}

final changeEmailControllerProvider = NotifierProvider.autoDispose
    .family<ChangeEmailController, ChangeEmailState, String?>(
      ChangeEmailController.new,
    );

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/failure.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/auth_repository.dart';
import 'auth_controller.dart';

enum OtpChannel { email, phone }

/// Shown as a "you're joining X" summary on top of the OTP field when
/// verification is the last step of accepting an invitation (as opposed
/// to a regular sign-in), so the resident sees *why* a code just went
/// out and what account they're about to create.
class RegistrationContext {
  const RegistrationContext({
    required this.residentialName,
    required this.unitName,
    this.fullName,
  });

  final String residentialName;
  final String unitName;
  final String? fullName;
}

/// Passed as `extra` when pushing `/verify-otp` — which identifier the
/// code was sent to, whether it's an email or SMS code, and (for a new
/// resident accepting an invitation) which unit they're joining.
class OtpVerifyArgs {
  const OtpVerifyArgs({
    required this.identifier,
    required this.channel,
    this.registration,
  });

  final String identifier;
  final OtpChannel channel;
  final RegistrationContext? registration;
}

/// SharedPreferences key: shows the biometric setup screen at most once,
/// right after a resident's first successful OTP verification.
const biometricSetupSeenPrefsKey = 'biometric_setup_seen';

/// Minimum wait before another code can be requested. A code has just
/// been sent when this screen opens, so the countdown starts right away.
const otpResendCooldownSeconds = 60;

/// Why the code could not be verified.
sealed class OtpVerifyError {
  const OtpVerifyError();
}

/// The code field doesn't hold a full 6-digit code yet.
class OtpIncomplete extends OtpVerifyError {
  const OtpIncomplete();
}

/// The backend rejected the code (wrong or expired).
class OtpInvalidCode extends OtpVerifyError {
  const OtpInvalidCode();
}

/// Verification could not be completed (connectivity, server...).
class OtpVerifyFailed extends OtpVerifyError {
  const OtpVerifyFailed(this.failure);
  final Failure failure;
}

class OtpVerifyState {
  const OtpVerifyState({
    this.isSubmitting = false,
    this.isResending = false,
    this.cooldownRemaining = otpResendCooldownSeconds,
    this.error,
  });

  final bool isSubmitting;
  final bool isResending;
  final int cooldownRemaining;
  final OtpVerifyError? error;

  OtpVerifyState copyWith({
    bool? isSubmitting,
    bool? isResending,
    int? cooldownRemaining,
    Object? error = _keep,
  }) => OtpVerifyState(
    isSubmitting: isSubmitting ?? this.isSubmitting,
    isResending: isResending ?? this.isResending,
    cooldownRemaining: cooldownRemaining ?? this.cooldownRemaining,
    error: identical(error, _keep) ? this.error : error as OtpVerifyError?,
  );
}

const _keep = Object();

/// One-off notifications the screen turns into toasts / navigation.
sealed class OtpEvent {
  const OtpEvent();
}

/// Offer biometric sign-in (first verification of a linked resident).
class ShowBiometricSetup extends OtpEvent {
  const ShowBiometricSetup();
}

class ResendSucceeded extends OtpEvent {
  const ResendSucceeded();
}

/// A new code could not be sent. [failure] is null for a rate limit.
class ResendFailed extends OtpEvent {
  const ResendFailed(this.failure);
  final Failure? failure;
}

/// Verifies the one-time code and handles the resend countdown. GoRouter's
/// auth redirect takes over once the session is set.
class OtpVerifyController extends Notifier<OtpVerifyState> {
  OtpVerifyController(this.args);

  final OtpVerifyArgs args;

  final _events = StreamController<OtpEvent>.broadcast();
  Timer? _cooldownTimer;
  bool _disposed = false;

  Stream<OtpEvent> get events => _events.stream;

  bool get _isEmail => args.channel == OtpChannel.email;

  @override
  OtpVerifyState build() {
    ref.onDispose(() {
      _disposed = true;
      _cooldownTimer?.cancel();
      _events.close();
    });
    _startTimer();
    return const OtpVerifyState();
  }

  void _startTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.cooldownRemaining - 1;
      state = state.copyWith(cooldownRemaining: remaining);
      if (remaining <= 0) timer.cancel();
    });
  }

  void _startCooldown() {
    state = state.copyWith(cooldownRemaining: otpResendCooldownSeconds);
    _startTimer();
  }

  Future<void> verify(String code) async {
    final token = code.trim();
    if (code.length != 6) {
      state = state.copyWith(error: const OtpIncomplete());
      return;
    }
    state = state.copyWith(isSubmitting: true, error: null);
    final repository = ref.read(authRepositoryProvider);
    try {
      final outcome = _isEmail
          ? await repository.verifyEmailOtp(
              email: args.identifier,
              token: token,
            )
          : await repository.verifyPhoneOtp(
              phone: args.identifier,
              token: token,
            );
      if (_disposed) return;
      if (outcome == OtpVerifyOutcome.invalidCode) {
        state = state.copyWith(
          isSubmitting: false,
          error: const OtpInvalidCode(),
        );
        return;
      }
      state = state.copyWith(isSubmitting: false);
      await _maybeOfferBiometricSetup();
    } catch (error) {
      if (_disposed) return;
      state = state.copyWith(
        isSubmitting: false,
        error: OtpVerifyFailed(Failure.from(error)),
      );
    }
  }

  /// Offers to set up biometric sign-in once, right after a resident's
  /// account is actually usable (unit linked) — never interrupting the
  /// invitation-linking gate.
  Future<void> _maybeOfferBiometricSetup() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(biometricSetupSeenPrefsKey) ?? false) return;
    try {
      final memberships = await ref.read(myMembershipsProvider.future);
      if (memberships.isEmpty) return;
    } on Failure {
      return;
    }
    await prefs.setBool(biometricSetupSeenPrefsKey, true);
    if (_disposed) return;
    _events.add(const ShowBiometricSetup());
  }

  Future<void> resend() async {
    if (state.cooldownRemaining > 0 || state.isResending) return;
    state = state.copyWith(isResending: true);
    final repository = ref.read(authRepositoryProvider);
    try {
      final outcome = _isEmail
          ? await repository.sendEmailOtp(args.identifier)
          : await repository.sendPhoneOtp(args.identifier);
      if (_disposed) return;
      if (outcome == OtpSendOutcome.rateLimited) {
        _failResend(null);
        return;
      }
      state = state.copyWith(isResending: false);
      _startCooldown();
      _events.add(const ResendSucceeded());
    } catch (error) {
      if (_disposed) return;
      _failResend(Failure.from(error));
    }
  }

  /// The server rate-limits too; wait out a full cooldown before retrying.
  void _failResend(Failure? failure) {
    state = state.copyWith(isResending: false);
    _startCooldown();
    _events.add(ResendFailed(failure));
  }
}

final otpVerifyControllerProvider = NotifierProvider.autoDispose
    .family<OtpVerifyController, OtpVerifyState, OtpVerifyArgs>(
      OtpVerifyController.new,
    );

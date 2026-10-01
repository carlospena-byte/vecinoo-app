import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/keyboard_safe_column.dart';
import '../../../core/widgets/otp_code_field.dart';
import '../../../core/widgets/vecinoo_brand.dart';
import '../../session/presentation/session_controller.dart';
import 'auth_controller.dart';
import '../../../core/widgets/gates_toast.dart';
import '../../../l10n/l10n.dart';

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
const _biometricSetupSeenPrefsKey = 'biometric_setup_seen';

/// Minimum wait before another code can be requested. A code has just
/// been sent when this screen opens, so the countdown starts right away.
const _resendCooldownSeconds = 60;

/// "02 / Verifica tu código" screen from Figma (file
/// `Bla1GPfXA7JkuZcYpVi2DS`, node `13:8`): verifies the 6-digit code
/// Supabase Auth sent to an email or phone — the only way residents
/// create or access their account now that there's no password.
/// GoRouter's auth redirect takes over once the session is set.
class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key, required this.args});

  final OtpVerifyArgs args;

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _codeController = TextEditingController();

  bool _isSubmitting = false;
  bool _isResending = false;
  Timer? _cooldownTimer;
  int _cooldownRemaining = _resendCooldownSeconds;
  String? _errorText;

  bool get _isEmail => widget.args.channel == OtpChannel.email;

  String _introText(BuildContext context) =>
      _isEmail ? context.l10n.authOtpIntroEmail : context.l10n.authOtpIntroSms;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownRemaining = _resendCooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _cooldownRemaining--);
      if (_cooldownRemaining <= 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_codeController.text.length != 6) {
      setState(() => _errorText = context.l10n.authEnterDigits(6));
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final token = _codeController.text.trim();
      if (_isEmail) {
        await authRepository.verifyEmailOtp(
          email: widget.args.identifier,
          token: token,
        );
      } else {
        await authRepository.verifyPhoneOtp(
          phone: widget.args.identifier,
          token: token,
        );
      }
      if (!mounted) return;
      await _maybeShowBiometricSetup();
      // Otherwise, GoRouter's auth redirect takes over once the session is set.
    } catch (e) {
      debugPrint('OTP verify failed: $e');
      setState(() => _errorText = context.l10n.authOtpWrongOrExpired);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Offers to set up biometric sign-in once, right after a resident's
  /// account is actually usable (unit linked) — never interrupting the
  /// invitation-linking gate.
  Future<void> _maybeShowBiometricSetup() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_biometricSetupSeenPrefsKey) ?? false) return;
    try {
      final memberships = await ref.read(myMembershipsProvider.future);
      if (memberships.isEmpty) return;
    } catch (_) {
      return;
    }
    await prefs.setBool(_biometricSetupSeenPrefsKey, true);
    if (!mounted) return;
    context.push('/setup-biometrics');
  }

  Future<void> _resend() async {
    if (_cooldownRemaining > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      if (_isEmail) {
        await authRepository.sendEmailOtp(widget.args.identifier);
      } else {
        await authRepository.sendPhoneOtp(widget.args.identifier);
      }
      if (mounted) {
        _startCooldown();
        showGatesToast(
          context,
          type: GatesToastType.success,
          title: context.l10n.authOtpResentTitle,
          message: context.l10n.authOtpResentMessage,
        );
      }
    } catch (e) {
      debugPrint('OTP resend failed: $e');
      if (mounted) {
        // The server rate-limits too; wait out a full cooldown before retrying.
        _startCooldown();
        showGatesToast(
          context,
          type: GatesToastType.error,
          title: context.l10n.authOtpResendFailedTitle,
          message: context.l10n.authOtpResendFailedMessage,
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: KeyboardSafeColumn(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                const VecinooWordmark(),
                const VecinooMark(),
                if (widget.args.registration != null) ...[
                  Text(
                    context.l10n.authInvitationValidated,
                    style: context.gatesText.caption.copyWith(
                      color: context.palette.textBrand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  _isEmail
                      ? context.l10n.authCheckEmail
                      : context.l10n.authCheckPhone,
                  style: GatesTypography.headingLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _introText(context),
                  style: GatesTypography.body.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.args.identifier,
                  style: GatesTypography.label.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                OtpCodeField(
                  controller: _codeController,
                  label: context.l10n.authVerificationCode,
                  errorText: _errorText,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  onCompleted: (_) => _verify(),
                ),
                const SizedBox(height: 16),
                GatesButton(
                  label: context.l10n.authVerifyAndSignIn,
                  onPressed: _isSubmitting ? null : _verify,
                  loading: _isSubmitting,
                ),
                Center(
                  child: TextButton(
                    onPressed: (_isResending || _cooldownRemaining > 0)
                        ? null
                        : _resend,
                    child: Text(
                      _isResending
                          ? context.l10n.authSending
                          : _cooldownRemaining > 0
                          ? context.l10n.authResendIn(_cooldownRemaining)
                          : context.l10n.authResend,
                      style: GatesTypography.label.copyWith(
                        color: _cooldownRemaining > 0
                            ? context.palette.textSecondary
                            : context.palette.textBrand,
                        decoration: _cooldownRemaining > 0
                            ? TextDecoration.none
                            : TextDecoration.underline,
                        decorationColor: context.palette.textBrand,
                      ),
                    ),
                  ),
                ),
                if (widget.args.registration != null) ...[
                  const SizedBox(height: 20),
                  _CommunityContext(registration: widget.args.registration!),
                ],
              ],
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 24, top: 10),
                child: _BackButton(onTap: () => context.pop()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Contexto / Residencial": which community, unit and resident the
/// account being activated belongs to, at the foot of the screen.
class _CommunityContext extends StatelessWidget {
  const _CommunityContext({required this.registration});

  final RegistrationContext registration;

  @override
  Widget build(BuildContext context) {
    final name = registration.fullName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.authCommunityAccess,
          style: context.gatesText.caption,
        ),
        const SizedBox(height: 4),
        Text(
          '${registration.unitName} · ${registration.residentialName}',
          style: GatesTypography.label.copyWith(
            fontWeight: FontWeight.w400,
            color: context.palette.textPrimary,
          ),
        ),
        if (name != null) ...[
          const SizedBox(height: 4),
          Text(
            context.l10n.authResidentName(name),
            style: context.gatesText.caption,
          ),
        ],
      ],
    );
  }
}

/// "Control / Volver": circular back button overlaid on the top-right
/// corner of the OTP screen.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.bgSurface,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.arrow_back,
            semanticLabel: context.l10n.commonBack,
            size: 20,
            color: context.palette.textPrimary,
          ),
        ),
      ),
    );
  }
}

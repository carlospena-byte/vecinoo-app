import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/keyboard_safe_column.dart';
import '../../../core/widgets/otp_code_field.dart';
import '../../../core/widgets/vecinoo_brand.dart';
import '../../../core/error/failure_messages.dart';
import 'auth_controller.dart';
import 'otp_verify_controller.dart';
import '../../../core/widgets/gates_toast.dart';
import '../../../l10n/l10n.dart';

export 'otp_verify_controller.dart'
    show OtpChannel, OtpVerifyArgs, RegistrationContext;

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

  StreamSubscription<OtpEvent>? _events;

  OtpVerifyController get _controller =>
      ref.read(otpVerifyControllerProvider(widget.args).notifier);

  bool get _isEmail => widget.args.channel == OtpChannel.email;

  String _introText(BuildContext context) =>
      _isEmail ? context.l10n.authOtpIntroEmail : context.l10n.authOtpIntroSms;

  @override
  void initState() {
    super.initState();
    _events = _controller.events.listen(_onEvent);
  }

  @override
  void dispose() {
    _events?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _onEvent(OtpEvent event) {
    if (!mounted) return;
    final l10n = context.l10n;
    switch (event) {
      case ShowBiometricSetup():
        context.push('/setup-biometrics');
      case ResendSucceeded():
        showGatesToast(
          context,
          type: GatesToastType.success,
          title: l10n.authOtpResentTitle,
          message: l10n.authOtpResentMessage,
        );
      case ResendFailed(:final failure):
        showGatesToast(
          context,
          type: GatesToastType.error,
          title: l10n.authOtpResendFailedTitle,
          message: withFailureDetail(
            failure == null ? null : failureDetail(l10n, failure),
            l10n.authOtpResendFailedMessage,
          ),
        );
    }
  }

  String? _errorText(OtpVerifyError? error) {
    final l10n = context.l10n;
    return switch (error) {
      null => null,
      OtpIncomplete() => l10n.authEnterDigits(6),
      OtpInvalidCode() => l10n.authOtpWrongOrExpired,
      OtpVerifyFailed(:final failure) => withFailureDetail(
        failureDetail(l10n, failure),
        l10n.authOtpWrongOrExpired,
      ),
    };
  }

  void _verify() => _controller.verify(_codeController.text);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpVerifyControllerProvider(widget.args));
    final cooldownRemaining = state.cooldownRemaining;
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
                  errorText: _errorText(state.error),
                  autofillHints: const [AutofillHints.oneTimeCode],
                  onCompleted: (_) => _verify(),
                ),
                const SizedBox(height: 16),
                GatesButton(
                  label: context.l10n.authVerifyAndSignIn,
                  onPressed: state.isSubmitting ? null : _verify,
                  loading: state.isSubmitting,
                ),
                Center(
                  child: TextButton(
                    onPressed: (state.isResending || cooldownRemaining > 0)
                        ? null
                        : _controller.resend,
                    child: Text(
                      state.isResending
                          ? context.l10n.authSending
                          : cooldownRemaining > 0
                          ? context.l10n.authResendIn(cooldownRemaining)
                          : context.l10n.authResend,
                      style: GatesTypography.label.copyWith(
                        color: cooldownRemaining > 0
                            ? context.palette.textSecondary
                            : context.palette.textBrand,
                        decoration: cooldownRemaining > 0
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
            TablerIcons.arrowLeft,
            semanticLabel: context.l10n.commonBack,
            size: 20,
            color: context.palette.textPrimary,
          ),
        ),
      ),
    );
  }
}

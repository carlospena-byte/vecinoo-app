import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/keyboard_safe_column.dart';
import '../../../core/widgets/otp_code_field.dart';
import '../../../core/widgets/vecinoo_brand.dart';
import '../../../core/error/failure_messages.dart';
import 'auth_controller.dart';
import 'register_controller.dart';
import '../../../core/widgets/gates_toast.dart';
import '../../../l10n/l10n.dart';

export 'register_controller.dart' show pendingInvitationCodePrefsKey;

/// "Validar invitación / Código no válido" screen from Figma (file
/// `Bla1GPfXA7JkuZcYpVi2DS`, node `61:454`): a resident proves they hold a
/// real invitation code an admin sent them. As soon as it's valid, the
/// sign-in code goes out automatically (the invitation already carries
/// the email) straight to otp_verify_screen.dart — there's no separate
/// "choose how to receive your code" step to click through.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _codeController = TextEditingController();

  StreamSubscription<RegisterEvent>? _events;

  @override
  void initState() {
    super.initState();
    _events = ref
        .read(registerControllerProvider.notifier)
        .events
        .listen(_onEvent);
  }

  @override
  void dispose() {
    _events?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _onEvent(RegisterEvent event) {
    if (!mounted) return;
    switch (event) {
      case RegisterCodeSent(:final args):
        context.push('/verify-otp', extra: args);
    }
  }

  void _acceptInvitation() => ref
      .read(registerControllerProvider.notifier)
      .acceptInvitation(_codeController.text);

  String? _errorText(RegisterError? error) {
    final l10n = context.l10n;
    return switch (error) {
      null => null,
      InvitationIncomplete() => l10n.authEnterDigits(invitationCodeLength),
      InvitationRejected() => l10n.authInvitationInvalid,
      RegisterFailed(:final failure) => withFailureDetail(
        failureDetail(l10n, failure),
        l10n.authInvitationInvalid,
      ),
    };
  }

  void _contactSupport() {
    showGatesToast(
      context,
      type: GatesToastType.info,
      title: context.l10n.authSupportTitle,
      message: context.l10n.authSupportMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerControllerProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: KeyboardSafeColumn(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
              children: [
                const VecinooWordmark(),
                const VecinooMark(),
                const Expanded(child: SizedBox()),
                Text(
                  context.l10n.authValidateCodeTitle,
                  style: GatesTypography.headingLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.authValidateCodeBody(invitationCodeLength),
                  style: context.gatesText.labelSecondary,
                ),
                const SizedBox(height: 16),
                OtpCodeField(
                  controller: _codeController,
                  label: context.l10n.authInvitationCode,
                  length: invitationCodeLength,
                  accentColor: context.palette.accentCoral,
                  helper: context.l10n.authInvitationHelper,
                  errorText: _errorText(state.error),
                  onCompleted: (_) => _acceptInvitation(),
                ),
                const SizedBox(height: 16),
                GatesButton(
                  label: context.l10n.authAcceptInvitation,
                  onPressed:
                      (state.isSubmitting ||
                          _codeController.text.length != invitationCodeLength)
                      ? null
                      : _acceptInvitation,
                  loading: state.isSubmitting,
                ),
                Center(
                  child: TextButton(
                    onPressed: _contactSupport,
                    child: Text(
                      context.l10n.authNoInvitationContactSupport,
                      style: GatesTypography.label.copyWith(
                        color: context.palette.textBrand,
                      ),
                    ),
                  ),
                ),
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

/// "Control / Volver": circular back button, matching the one on
/// otp_verify_screen.dart.
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

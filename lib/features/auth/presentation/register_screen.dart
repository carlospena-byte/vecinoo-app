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
import 'otp_verify_screen.dart';
import '../../../core/widgets/gates_toast.dart';

/// SharedPreferences key for an already-validated invitation code, saved
/// right before we navigate to the OTP screen (there's no active session
/// yet — passwordless sign-in only completes once the code is verified)
/// — see pending_link_screen.dart, which redeems it after that happens.
const pendingInvitationCodePrefsKey = 'pending_invitation_code';

const _invitationCodeLength = 6;

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

  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _acceptInvitation() async {
    if (_codeController.text.length != _invitationCodeLength) {
      setState(() => _errorText = 'Ingresa los $_invitationCodeLength dígitos');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    final code = _codeController.text.trim();
    try {
      final invitation = await ref
          .read(sessionRepositoryProvider)
          .validateInvitation(code: code);
      await ref.read(authRepositoryProvider).sendEmailOtp(invitation.email);

      // No active session until the code is verified on the next screen,
      // so save the already-validated invitation code for
      // pending_link_screen.dart to redeem once sign-in actually completes.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(pendingInvitationCodePrefsKey, code);

      if (!mounted) return;
      context.push(
        '/verify-otp',
        extra: OtpVerifyArgs(
          identifier: invitation.email,
          channel: OtpChannel.email,
          registration: RegistrationContext(
            residentialName: invitation.residentialName,
            unitName: invitation.unitName,
            fullName: invitation.fullName,
          ),
        ),
      );
    } catch (e) {
      // The message below is deliberately generic, but this keeps real
      // bugs — like an unreachable Supabase URL — from looking identical
      // to a bad invitation code in the debug console.
      debugPrint('Accept invitation failed: $e');
      setState(() => _errorText = 'Código inválido, ya usado o expirado.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _contactSupport() {
    showGatesToast(
      context,
      type: GatesToastType.info,
      title: 'Contacta a soporte',
      message: 'Escríbenos a soporte@vecinoo.app',
    );
  }

  @override
  Widget build(BuildContext context) {
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
                Text('Valida tu código', style: GatesTypography.headingLarge),
                const SizedBox(height: 8),
                Text(
                  'Ingresa el código de $_invitationCodeLength dígitos que recibiste en tu invitación.',
                  style: context.gatesText.labelSecondary,
                ),
                const SizedBox(height: 16),
                OtpCodeField(
                  controller: _codeController,
                  label: 'Código de invitación',
                  length: _invitationCodeLength,
                  accentColor: context.palette.accentCoral,
                  helper: 'Revisa tu tarjeta o correo de bienvenida.',
                  errorText: _errorText,
                  onCompleted: (_) => _acceptInvitation(),
                ),
                const SizedBox(height: 16),
                GatesButton(
                  label: 'Aceptar invitación',
                  onPressed:
                      (_isSubmitting ||
                          _codeController.text.length != _invitationCodeLength)
                      ? null
                      : _acceptInvitation,
                  loading: _isSubmitting,
                ),
                Center(
                  child: TextButton(
                    onPressed: _contactSupport,
                    child: Text(
                      '¿No recibiste tu invitación? Contactar soporte',
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
            size: 20,
            color: context.palette.textPrimary,
          ),
        ),
      ),
    );
  }
}

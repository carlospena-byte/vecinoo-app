import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_text_field.dart';
import '../../../core/widgets/keyboard_safe_column.dart';
import '../../../core/widgets/vecinoo_brand.dart';
import '../../session/data/session_repository.dart';
import '../../session/presentation/session_controller.dart';
import 'auth_controller.dart';
import 'otp_verify_screen.dart';
import '../../../l10n/l10n.dart';

/// "01 · Acceso administrado" screen from Figma (file
/// `Bla1GPfXA7JkuZcYpVi2DS`, node `13:2`): passwordless email sign-in —
/// send a one-time code and hand off to [OtpVerifyScreen].
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    final email = _emailController.text.trim();
    try {
      final status = await ref
          .read(sessionRepositoryProvider)
          .checkEmailLoginStatus(email);
      if (status == EmailLoginStatus.invited) {
        // An admin already invited this email but it hasn't been linked to
        // a unit yet — sending a sign-in code here would just create a
        // disconnected account instead of the "Valida tu código" flow that
        // actually activates it.
        setState(() => _errorText = context.l10n.authInvitationPending);
        return;
      }
      if (status == EmailLoginStatus.unknown) {
        // No auth account/profile matches this email, or it exists but no
        // admin has invited it yet — sending an OTP here would silently
        // create a disconnected account instead of surfacing the real
        // problem.
        setState(() => _errorText = context.l10n.authEmailUnknown);
        return;
      }
      await ref.read(authRepositoryProvider).sendEmailOtp(email);
      if (!mounted) return;
      context.push(
        '/verify-otp',
        extra: OtpVerifyArgs(identifier: email, channel: OtpChannel.email),
      );
    } catch (e) {
      // Anything here is usually a connectivity problem (e.g. the Android
      // emulator can't reach the configured SUPABASE_URL) rather than a bad
      // identifier — keep the real exception in the console.
      debugPrint('Send OTP failed: $e');
      setState(() => _errorText = context.l10n.authSendCodeFailed);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
              padding: const EdgeInsets.all(24),
              children: [
                const VecinooWordmark(),
                const VecinooMark(),
                Text(
                  context.l10n.authLoginTitle,
                  style: GatesTypography.headingLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.authLoginSubtitle,
                  style: GatesTypography.body.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
                const Expanded(child: SizedBox()),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GatesTextField(
                        label: context.l10n.authEmailLabel,
                        hintText: context.l10n.authEmailHint,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                        validator: (v) => (v == null || !v.contains('@'))
                            ? context.l10n.authEmailInvalid
                            : null,
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorText!,
                          style: context.gatesText.caption.copyWith(
                            color: context.palette.statusError,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      GatesButton(
                        label: context.l10n.commonContinue,
                        onPressed: _isSubmitting ? null : _submitEmail,
                        loading: _isSubmitting,
                      ),
                    ],
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => context.push('/register'),
                    child: Text(
                      context.l10n.authHaveInvitationCode,
                      style: GatesTypography.label.copyWith(
                        color: context.palette.textBrand,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

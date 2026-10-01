import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_text_field.dart';
import '../../../core/widgets/keyboard_safe_column.dart';
import '../../../core/widgets/vecinoo_brand.dart';
import '../../../core/error/failure_messages.dart';
import 'auth_controller.dart';
import 'login_controller.dart';
import 'otp_verify_controller.dart';
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

  StreamSubscription<LoginEvent>? _events;

  @override
  void initState() {
    super.initState();
    _events = ref
        .read(loginControllerProvider.notifier)
        .events
        .listen(_onEvent);
  }

  @override
  void dispose() {
    _events?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _onEvent(LoginEvent event) {
    if (!mounted) return;
    switch (event) {
      case LoginCodeSent(:final email):
        context.push(
          '/verify-otp',
          extra: OtpVerifyArgs(identifier: email, channel: OtpChannel.email),
        );
    }
  }

  void _submitEmail() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref
        .read(loginControllerProvider.notifier)
        .submit(_emailController.text.trim());
  }

  String? _errorText(LoginError? error) {
    final l10n = context.l10n;
    return switch (error) {
      null => null,
      InvitationPending() => l10n.authInvitationPending,
      EmailUnknown() => l10n.authEmailUnknown,
      // Anything here is usually a connectivity problem (e.g. the Android
      // emulator can't reach the configured SUPABASE_URL) rather than a bad
      // identifier.
      SendCodeFailed(:final failure) => withFailureDetail(
        failure == null ? null : failureDetail(l10n, failure),
        l10n.authSendCodeFailed,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final errorText = _errorText(state.error);
    final isSubmitting = state.isSubmitting;
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
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorText,
                          style: context.gatesText.caption.copyWith(
                            color: context.palette.statusError,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      GatesButton(
                        label: context.l10n.commonContinue,
                        onPressed: isSubmitting ? null : _submitEmail,
                        loading: isSubmitting,
                      ),
                    ],
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: isSubmitting
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

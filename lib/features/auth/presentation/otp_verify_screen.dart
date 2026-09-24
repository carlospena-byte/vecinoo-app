import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_text_field.dart';
import 'auth_controller.dart';

enum OtpChannel { email, phone }

/// Passed as `extra` when pushing `/verify-otp` — which identifier the
/// code was sent to, and whether it's an email or SMS code.
class OtpVerifyArgs {
  const OtpVerifyArgs({required this.identifier, required this.channel});

  final String identifier;
  final OtpChannel channel;
}

/// Verifies the 6-digit code Supabase Auth sent to an email or phone —
/// the only way residents create or access their account now that
/// there's no password. GoRouter's auth redirect takes over once the
/// session is set.
class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key, required this.args});

  final OtpVerifyArgs args;

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _isSubmitting = false;
  bool _isResending = false;
  String? _errorText;

  bool get _isEmail => widget.args.channel == OtpChannel.email;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final token = _codeController.text.trim();
      if (_isEmail) {
        await authRepository.verifyEmailOtp(email: widget.args.identifier, token: token);
      } else {
        await authRepository.verifyPhoneOtp(phone: widget.args.identifier, token: token);
      }
      // GoRouter's auth redirect takes over once the session is set.
    } catch (e) {
      debugPrint('OTP verify failed: $e');
      setState(() => _errorText = 'Código incorrecto o expirado.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      if (_isEmail) {
        await authRepository.sendEmailOtp(widget.args.identifier);
      } else {
        await authRepository.sendPhoneOtp(widget.args.identifier);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código reenviado')),
        );
      }
    } catch (_) {
      // Ignore — rate limiting is expected on rapid taps.
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _AmbientGlow(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: GatesSpacing.space12),
                        alignment: Alignment.centerLeft,
                      ),
                      onPressed: () => context.pop(),
                      child: Text(
                        'Volver',
                        style: GatesTypography.label.copyWith(color: GatesColors.textBrand),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _BrandBlock(),
                  const SizedBox(height: 24),
                  Text('Verifica tu código', style: GatesTypography.headingLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Enviamos un código de 6 dígitos a ${widget.args.identifier}',
                    style: GatesTypography.body.copyWith(color: GatesColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GatesTextField(
                          label: 'Código de verificación',
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          validator: (v) => (v == null || v.length != 6) ? 'Ingresa los 6 dígitos' : null,
                        ),
                        if (_errorText != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorText!,
                            style: GatesTypography.caption.copyWith(color: GatesColors.statusError),
                          ),
                        ],
                        const SizedBox(height: 16),
                        GatesButton(
                          label: 'Verificar',
                          onPressed: _isSubmitting ? null : _verify,
                          loading: _isSubmitting,
                        ),
                        Center(
                          child: TextButton(
                            onPressed: _isResending ? null : _resend,
                            child: Text(
                              _isResending ? 'Enviando...' : 'Reenviar código',
                              style: GatesTypography.label.copyWith(color: GatesColors.textBrand),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "gates" wordmark + small-caps subtitle, matching the block on the login
/// screen.
class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('gates', style: GatesTypography.headingMedium.copyWith(color: GatesColors.textBrand)),
        const SizedBox(height: 4),
        Text(
          'PARA RESIDENTES',
          style: GatesTypography.caption.copyWith(letterSpacing: 0.6),
        ),
      ],
    );
  }
}

/// Subtle warm radial glow behind the auth screens' content, matching the
/// Figma "Ambient / warm glow" decoration. Purely cosmetic.
class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -80,
      top: 60,
      child: IgnorePointer(
        child: Container(
          width: 420,
          height: 360,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                GatesColors.bgAccent.withValues(alpha: 0.55),
                GatesColors.bgAccent.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_text_field.dart';
import 'auth_controller.dart';
import 'otp_verify_screen.dart';

/// Passwordless: both tabs just send a one-time code and hand off to
/// OtpVerifyScreen — there's nothing to type in besides the identifier.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isEmailMethod = true;

  final _emailFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  final _phoneFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    final email = _emailController.text.trim();
    try {
      await ref.read(authRepositoryProvider).sendEmailOtp(email);
      if (!mounted) return;
      context.push('/verify-otp', extra: OtpVerifyArgs(identifier: email, channel: OtpChannel.email));
    } catch (e) {
      setState(() => _errorText = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitPhone() async {
    if (!(_phoneFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    final phone = _phoneController.text.trim();
    try {
      await ref.read(authRepositoryProvider).sendPhoneOtp(phone);
      if (!mounted) return;
      context.push('/verify-otp', extra: OtpVerifyArgs(identifier: phone, channel: OtpChannel.phone));
    } catch (e) {
      setState(() => _errorText = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _friendlyError(Object e) {
    // Anything here is usually a connectivity problem (e.g. the Android
    // emulator can't reach the configured SUPABASE_URL) rather than a bad
    // identifier — keep the real exception in the console.
    debugPrint('Send OTP failed: $e');
    return 'No se pudo enviar el código. Intenta de nuevo.';
  }

  void _selectMethod(bool isEmail) {
    if (_isEmailMethod == isEmail) return;
    setState(() {
      _isEmailMethod = isEmail;
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _AmbientGlow(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BrandBlock(),
                  const SizedBox(height: 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Tu hogar,\nmás cerca.', style: GatesTypography.headingLarge),
                      const SizedBox(height: 12),
                      Text(
                        'Ingresa a tu comunidad con un código de un solo uso.',
                        style: GatesTypography.body.copyWith(color: GatesColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MethodToggle(isEmailSelected: _isEmailMethod, onSelect: _selectMethod),
                      const SizedBox(height: 16),
                      _isEmailMethod ? _buildEmailForm() : _buildPhoneForm(),
                    ],
                  ),
                  const Expanded(child: SizedBox()),
                  Center(
                    child: TextButton(
                      onPressed: _isSubmitting ? null : () => context.push('/register'),
                      child: Text(
                        '¿Tienes un código de invitación? Regístrate',
                        style: GatesTypography.label.copyWith(color: GatesColors.textBrand),
                      ),
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

  Widget _buildEmailForm() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GatesTextField(
            label: 'Correo electrónico',
            hintText: 'nombre@correo.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(_errorText!, style: GatesTypography.caption.copyWith(color: GatesColors.statusError)),
          ],
          const SizedBox(height: 16),
          GatesButton(
            label: 'Enviar código',
            onPressed: _isSubmitting ? null : _submitEmail,
            loading: _isSubmitting,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneForm() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GatesTextField(
            label: 'Teléfono',
            hintText: '+50412345678',
            helperText: 'Incluye el código de país.',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            validator: (v) =>
                (v == null || !v.trim().startsWith('+') || v.trim().length < 8)
                    ? 'Incluye el código de país, ej. +504...'
                    : null,
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(_errorText!, style: GatesTypography.caption.copyWith(color: GatesColors.statusError)),
          ],
          const SizedBox(height: 16),
          GatesButton(
            label: 'Enviar código',
            onPressed: _isSubmitting ? null : _submitPhone,
            loading: _isSubmitting,
          ),
        ],
      ),
    );
  }
}

/// "gates" wordmark + small-caps subtitle, reused on the login and OTP
/// verification screens.
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

/// "Método de acceso" segmented control (Correo / Teléfono).
class _MethodToggle extends StatelessWidget {
  const _MethodToggle({required this.isEmailSelected, required this.onSelect});

  final bool isEmailSelected;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(GatesSpacing.space8),
      decoration: BoxDecoration(
        color: GatesColors.bgSubtle,
        borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
      ),
      child: Row(
        children: [
          Expanded(child: _segment(label: 'Correo', selected: isEmailSelected, onTap: () => onSelect(true))),
          const SizedBox(width: GatesSpacing.space4),
          Expanded(child: _segment(label: 'Teléfono', selected: !isEmailSelected, onTap: () => onSelect(false))),
        ],
      ),
    );
  }

  Widget _segment({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? GatesColors.bgSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
        ),
        child: Text(
          label,
          style: GatesTypography.label.copyWith(
            color: selected ? GatesColors.textBrand : GatesColors.textSecondary,
          ),
        ),
      ),
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

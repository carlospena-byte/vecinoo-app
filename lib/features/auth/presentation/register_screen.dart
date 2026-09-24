import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_text_field.dart';
import '../../session/data/session_repository.dart';
import '../../session/presentation/session_controller.dart';
import 'auth_controller.dart';
import 'otp_verify_screen.dart';

/// SharedPreferences key for an already-validated invitation code, saved
/// right before we navigate to the OTP screen (there's no active session
/// yet — passwordless sign-in only completes once the code is verified)
/// — see pending_link_screen.dart, which redeems it after that happens.
const pendingInvitationCodePrefsKey = 'pending_invitation_code';

enum _Step { invite, method, phone }

/// Registration is invitation-only and passwordless: a resident first
/// proves they hold a real code an admin sent them (validated against
/// the email it was sent to), then picks an email or SMS code to finish
/// creating their account.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  _Step _step = _Step.invite;

  final _inviteFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  final _phoneFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  InvitationPreview? _invitation;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _verifyInvitation() async {
    if (!(_inviteFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      final invitation = await ref.read(sessionRepositoryProvider).validateInvitation(
            email: _emailController.text.trim(),
            code: _codeController.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _invitation = invitation;
        _step = _Step.method;
      });
    } catch (e) {
      // The UI message below is deliberately generic (don't reveal
      // whether it's the email or the code that's wrong), but this keeps
      // real bugs — like an unreachable Supabase URL — from looking
      // identical to a bad invitation code in the debug console.
      debugPrint('validateInvitation failed: $e');
      setState(() => _errorText = 'Código inválido, ya usado, expirado, o no corresponde a ese correo.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _saveCodeAndGoToOtp(OtpVerifyArgs args) async {
    // No active session until the code is verified on the next screen, so
    // save the already-validated invitation code for
    // pending_link_screen.dart to redeem once sign-in actually completes.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(pendingInvitationCodePrefsKey, _codeController.text.trim());
    if (!mounted) return;
    context.push('/verify-otp', extra: args);
  }

  Future<void> _continueWithEmail() async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    final email = _emailController.text.trim();
    try {
      await ref.read(authRepositoryProvider).sendEmailOtp(email);
      await _saveCodeAndGoToOtp(OtpVerifyArgs(identifier: email, channel: OtpChannel.email));
    } catch (e) {
      setState(() => _errorText = 'No se pudo enviar el código. Intenta de nuevo.');
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
      await _saveCodeAndGoToOtp(OtpVerifyArgs(identifier: phone, channel: OtpChannel.phone));
    } catch (e) {
      setState(() => _errorText = 'No se pudo enviar el código. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GatesColors.bgSubtle,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.invite:
        return _buildInviteForm();
      case _Step.method:
        return _buildMethodChoice();
      case _Step.phone:
        return _buildPhoneForm();
    }
  }

  Widget _buildInviteForm() {
    return Form(
      key: _inviteFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _BackLink(label: 'Volver al inicio', onTap: () => context.pop()),
          const SizedBox(height: 24),
          const _BrandHeader(),
          const SizedBox(height: 24),
          Text('Crear cuenta', style: GatesTypography.headingLarge),
          const SizedBox(height: 12),
          Text(
            'Ingresa el correo y el código de invitación que te compartió el '
            'administrador de tu residencial.',
            style: GatesTypography.body.copyWith(color: GatesColors.textSecondary),
          ),
          const SizedBox(height: 24),
          GatesTextField(
            label: 'Correo electrónico',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
          ),
          const SizedBox(height: 16),
          GatesTextField(
            label: 'Código de invitación',
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            helperText: '8 caracteres alfanuméricos.',
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu código' : null,
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorText!,
              style: GatesTypography.body.copyWith(
                fontSize: 14,
                height: 20 / 14,
                color: GatesColors.statusError,
              ),
            ),
          ],
          const SizedBox(height: 16),
          GatesButton(
            label: 'Verificar',
            onPressed: _isSubmitting ? null : _verifyInvitation,
            loading: _isSubmitting,
          ),
        ],
      ),
    );
  }

  Widget _buildMethodChoice() {
    final invitation = _invitation!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _BackLink(
          label: 'Volver',
          onTap: () => setState(() {
            _errorText = null;
            _step = _Step.invite;
          }),
        ),
        const SizedBox(height: 24),
        const _BrandHeader(),
        const SizedBox(height: 24),
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: GatesColors.bgAccent,
            borderRadius: BorderRadius.circular(32),
          ),
          child: const Icon(Icons.check_rounded, color: GatesColors.textBrand, size: 28),
        ),
        const SizedBox(height: 16),
        Text('Tu comunidad te espera.', style: GatesTypography.headingLarge),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(GatesSpacing.space16),
          decoration: BoxDecoration(
            color: GatesColors.bgSurface,
            border: Border.all(color: GatesColors.borderDefault),
            borderRadius: BorderRadius.circular(GatesRadius.radius16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Te unirás a',
                style: GatesTypography.body.copyWith(fontSize: 14, height: 20 / 14, color: GatesColors.textBrand),
              ),
              Text(
                '${invitation.unitName} · ${invitation.residentialName}',
                style: GatesTypography.headingMedium.copyWith(fontSize: 20, height: 28 / 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Te enviaremos un código de un solo uso para terminar de crear tu cuenta.',
          style: GatesTypography.body.copyWith(color: GatesColors.textBrand),
        ),
        const SizedBox(height: 16),
        if (_errorText != null) ...[
          Text(
            _errorText!,
            style: GatesTypography.body.copyWith(
              fontSize: 14,
              height: 20 / 14,
              color: GatesColors.statusError,
            ),
          ),
          const SizedBox(height: 16),
        ],
        GatesButton(
          label: 'Enviar código a ${_emailController.text.trim()}',
          onPressed: _isSubmitting ? null : _continueWithEmail,
          loading: _isSubmitting,
        ),
        const SizedBox(height: 12),
        GatesButton(
          label: 'Usar mi teléfono en su lugar',
          style: GatesButtonStyle.secondary,
          onPressed: _isSubmitting
              ? null
              : () => setState(() {
                    _errorText = null;
                    _step = _Step.phone;
                  }),
        ),
      ],
    );
  }

  Widget _buildPhoneForm() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _BackLink(
            label: 'Volver',
            onTap: () => setState(() {
              _errorText = null;
              _step = _Step.method;
            }),
          ),
          const SizedBox(height: 24),
          const _BrandHeader(),
          const SizedBox(height: 24),
          Text('Usa tu teléfono', style: GatesTypography.headingLarge),
          const SizedBox(height: 12),
          Text(
            'Recibe el código de un solo uso por SMS para terminar de crear tu cuenta.',
            style: GatesTypography.body.copyWith(color: GatesColors.textSecondary),
          ),
          const SizedBox(height: 24),
          GatesTextField(
            label: 'Teléfono',
            hintText: '+50412345678',
            helperText: 'Incluye el código de país.',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: (v) =>
                (v == null || !v.trim().startsWith('+') || v.trim().length < 8)
                    ? 'Incluye el código de país, ej. +504...'
                    : null,
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorText!,
              style: GatesTypography.body.copyWith(
                fontSize: 14,
                height: 20 / 14,
                color: GatesColors.statusError,
              ),
            ),
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

/// "gates" wordmark + "PARA RESIDENTES" caption, shared across the
/// registration / onboarding flow.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('gates', style: GatesTypography.headingMedium.copyWith(color: GatesColors.textBrand)),
        const SizedBox(height: GatesSpacing.space4),
        Text('PARA RESIDENTES', style: GatesTypography.caption),
      ],
    );
  }
}

/// Text-only back link used in place of the default AppBar back chevron.
class _BackLink extends StatelessWidget {
  const _BackLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: GatesSpacing.space12),
          foregroundColor: GatesColors.textBrand,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label, style: GatesTypography.label.copyWith(color: GatesColors.textBrand)),
      ),
    );
  }
}

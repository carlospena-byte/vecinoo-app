import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_text_field.dart';
import 'profile_controller.dart';

/// Shown right after first sign-in when `profiles.first_name`/`last_name`
/// are still empty (the `handle_auth_user_created` trigger only fills
/// email, and phone sign-up fills neither).
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(profileRepositoryProvider).updateMine(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          );
      ref.invalidate(myProfileProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar. Intenta de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myProfileProvider).value;
    if (profile != null && _phoneController.text.isEmpty) {
      _phoneController.text = profile.phone ?? '';
    }

    return Scaffold(
      backgroundColor: GatesColors.bgSubtle,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('gates', style: GatesTypography.headingMedium.copyWith(color: GatesColors.textBrand)),
                    const SizedBox(height: GatesSpacing.space4),
                    Text('PARA RESIDENTES', style: GatesTypography.caption),
                  ],
                ),
                const SizedBox(height: 32),
                Text('Completa tu perfil', style: GatesTypography.headingLarge),
                const SizedBox(height: 12),
                Text(
                  'Solo faltan unos datos para darte la bienvenida.',
                  style: GatesTypography.body.copyWith(color: GatesColors.textSecondary),
                ),
                const SizedBox(height: 32),
                GatesTextField(
                  label: 'Nombre',
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                GatesTextField(
                  label: 'Apellido',
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                GatesTextField(
                  label: 'Teléfono (opcional)',
                  hintText: '+50412345678',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                GatesButton(
                  label: 'Continuar',
                  onPressed: _isSubmitting ? null : _submit,
                  loading: _isSubmitting,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

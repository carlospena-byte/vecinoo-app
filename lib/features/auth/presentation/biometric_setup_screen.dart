import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/biometric_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_toast.dart';
import '../../../core/widgets/keyboard_safe_column.dart';
import '../../../core/widgets/vecinoo_brand.dart';
import '../../../l10n/l10n.dart';

/// "02b / Configura biometría" screen from Figma (file
/// `Bla1GPfXA7JkuZcYpVi2DS`, node `46:82`): offered once, right after a
/// resident's first OTP verification (see `otp_verify_screen.dart`).
///
/// "Configurar" runs the device's biometric prompt and, when passed, turns
/// biometric unlock on (the same switch as in the profile); either way the
/// resident continues into the app.
class BiometricSetupScreen extends ConsumerStatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  ConsumerState<BiometricSetupScreen> createState() =>
      _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen> {
  bool _busy = false;

  Future<void> _setUp() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    final result = await ref
        .read(biometricEnabledProvider.notifier)
        .enable(l10n.profileBiometricReason);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case BiometricEnableResult.enabled:
        context.go('/');
      case BiometricEnableResult.unavailable:
        showGatesToast(
          context,
          type: GatesToastType.warning,
          title: l10n.profileBiometricUnavailable,
        );
      case BiometricEnableResult.cancelled:
        showGatesToast(
          context,
          type: GatesToastType.info,
          title: l10n.profileBiometricCancelled,
        );
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
                Text(
                  context.l10n.authBiometricTitle,
                  style: GatesTypography.headingLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.authBiometricBody,
                  style: GatesTypography.body.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
                const Expanded(child: SizedBox()),
                GatesButton(
                  label: context.l10n.authBiometricSetup,
                  loading: _busy,
                  onPressed: _busy ? null : _setUp,
                ),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/'),
                    child: Text(
                      context.l10n.authBiometricSkip,
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

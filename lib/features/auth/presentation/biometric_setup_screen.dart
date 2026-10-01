import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/keyboard_safe_column.dart';
import '../../../core/widgets/vecinoo_brand.dart';
import '../../../l10n/l10n.dart';

/// "02b / Configura biometría" screen from Figma (file
/// `Bla1GPfXA7JkuZcYpVi2DS`, node `46:82`): offered once, right after a
/// resident's first OTP verification (see `otp_verify_screen.dart`).
///
/// UI and navigation only — neither button wires up real device biometrics
/// yet, they just continue into the app.
class BiometricSetupScreen extends StatelessWidget {
  const BiometricSetupScreen({super.key});

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
                  onPressed: () => context.go('/'),
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

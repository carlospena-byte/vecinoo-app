import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/keyboard_safe_column.dart';
import '../../../core/widgets/vecinoo_brand.dart';

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
                Text('Entra más rápido', style: GatesTypography.headingLarge),
                const SizedBox(height: 12),
                Text(
                  'Usa tu rostro o huella para entrar.\nPuedes configurarlo más adelante.',
                  style: GatesTypography.body.copyWith(
                    color: GatesColors.textPrimary,
                  ),
                ),
                const Expanded(child: SizedBox()),
                GatesButton(
                  label: 'Configurar biometría',
                  onPressed: () => context.go('/'),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/'),
                    child: Text(
                      'Omitir por ahora',
                      style: GatesTypography.label.copyWith(
                        color: GatesColors.textBrand,
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

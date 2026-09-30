import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../session/presentation/session_controller.dart';

/// "V03 · Nueva visita" — Figma node `118:256`. Lets the resident pick which
/// kind of visit to create, then hands off to the matching create-visit
/// screen (each keeps managing its own route/back stack).
class CreateVisitTypeScreen extends ConsumerWidget {
  const CreateVisitTypeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(selectedMembershipProvider).value;
    if (membership == null) return const LoadingView();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            GatesSpacing.space24,
            GatesSpacing.space16,
            GatesSpacing.space24,
            GatesSpacing.space24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_back, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: GatesSpacing.space12),
                  Text('¿Quién viene?', style: GatesTypography.headingMedium),
                ],
              ),
              const SizedBox(height: 20),
              Text('Acceso para', style: GatesTypography.labelSecondary),
              const SizedBox(height: GatesSpacing.space4),
              Text(
                membership.label,
                style: GatesTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: GatesSpacing.space12),
              _ActionRow(
                icon: Icons.person_outline,
                title: 'Invitado',
                subtitle: 'Crea una invitación con registro del visitante',
                onTap: () => context.push('/visits/new/fastlane'),
              ),
              const SizedBox(height: GatesSpacing.space12),
              _ActionRow(
                icon: Icons.inventory_2_outlined,
                title: 'Delivery o proveedor',
                subtitle: 'Autoriza una entrega o servicio',
                onTap: () => context.push('/visits/new/delivery'),
              ),
              const SizedBox(height: GatesSpacing.space12),
              _ActionRow(
                icon: Icons.repeat,
                title: 'Acceso frecuente',
                subtitle: 'Para personas que vienen regularmente',
                onTap: () => context.push('/visits/new/frequent'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Action row" — Figma node `330:917`. The whole surface is tappable; no
/// trailing "Continuar" button per the component's usage notes.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(GatesRadius.radius16),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.all(GatesSpacing.space16),
        decoration: BoxDecoration(
          color: GatesColors.bgSurface,
          border: Border.all(color: GatesColors.borderDefault),
          borderRadius: BorderRadius.circular(GatesRadius.radius16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: GatesColors.bgSubtle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: GatesColors.textPrimary),
            ),
            const SizedBox(width: GatesSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GatesTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 24 / 16,
                    ),
                  ),
                  const SizedBox(height: GatesSpacing.space4),
                  Text(subtitle, style: GatesTypography.labelSecondary),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: GatesColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

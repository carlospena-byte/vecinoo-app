import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import 'session_controller.dart';

/// Shown when the resident belongs to more than one unit/residential and
/// no prior selection is saved.
class UnitSelectorScreen extends ConsumerWidget {
  const UnitSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships = ref.watch(myMembershipsProvider).value ?? [];

    return Scaffold(
      backgroundColor: GatesColors.bgSubtle,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Cerrar sesión',
                  icon: const Icon(
                    Icons.logout,
                    color: GatesColors.textSecondary,
                  ),
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'gates',
                    style: GatesTypography.headingMedium.copyWith(
                      color: GatesColors.textBrand,
                    ),
                  ),
                  const SizedBox(height: GatesSpacing.space4),
                  Text('PARA RESIDENTES', style: GatesTypography.caption),
                ],
              ),
              const SizedBox(height: 32),
              Text('Selecciona tu unidad', style: GatesTypography.headingLarge),
              const SizedBox(height: 12),
              Text(
                'Elige la unidad que quieres consultar.',
                style: GatesTypography.body.copyWith(
                  color: GatesColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: memberships.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final membership = memberships[index];
                    return _UnitTile(
                      label:
                          '${membership.unitName} · ${membership.residentialName}',
                      onTap: () => ref
                          .read(selectedMembershipProvider.notifier)
                          .select(membership),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped selectable row used to pick a linked unit, matching the
/// Figma "Elegir" rows (label centered, trailing arrow).
class _UnitTile extends StatelessWidget {
  const _UnitTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: GatesColors.bgSurface,
        border: Border.all(color: GatesColors.borderDefault),
        borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GatesSpacing.space16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: GatesTypography.label.copyWith(
                      color: GatesColors.textBrand,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: GatesSpacing.space8),
                const Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: GatesColors.textBrand,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

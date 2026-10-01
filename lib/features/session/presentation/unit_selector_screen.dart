import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import 'session_controller.dart';
import '../../../l10n/l10n.dart';

/// Shown when the resident belongs to more than one unit/residential and
/// no prior selection is saved.
class UnitSelectorScreen extends ConsumerWidget {
  const UnitSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships = ref.watch(myMembershipsProvider).value ?? [];

    return Scaffold(
      backgroundColor: context.palette.bgSubtle,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: context.l10n.commonLogout,
                  icon: Icon(
                    Icons.logout,
                    color: context.palette.textSecondary,
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
                      color: context.palette.textBrand,
                    ),
                  ),
                  const SizedBox(height: GatesSpacing.space4),
                  Text(
                    context.l10n.commonForResidents,
                    style: context.gatesText.caption,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                context.l10n.sessionSelectUnitTitle,
                style: GatesTypography.headingLarge,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.sessionSelectUnitBody,
                style: GatesTypography.body.copyWith(
                  color: context.palette.textSecondary,
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
        color: context.palette.bgSurface,
        border: Border.all(color: context.palette.borderDefault),
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
                      color: context.palette.textBrand,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: GatesSpacing.space8),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: context.palette.textBrand,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

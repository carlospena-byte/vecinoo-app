import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/failure_messages.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/widgets/gates_segmented_tabs.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../session/presentation/session_controller.dart';
import 'profile_controller.dart';
import '../../../l10n/l10n.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final membership = ref.watch(selectedMembershipProvider).value;
    final memberships = ref.watch(myMembershipsProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.commonProfile)),
      body: profileAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: withFailureDetail(
            failureDetail(context.l10n, Failure.from(e)),
            context.l10n.profileLoadFailed,
          ),
          onRetry: () => ref.invalidate(myProfileProvider),
        ),
        data: (profile) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: context.palette.bgAccent,
                foregroundColor: context.palette.textBrand,
                child: Text(
                  profile.displayName.isNotEmpty
                      ? profile.displayName[0].toUpperCase()
                      : '?',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  profile.displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    if (profile.email != null)
                      ListTile(
                        leading: const Icon(TablerIcons.mail),
                        title: Text(profile.email!),
                      ),
                    if (profile.phone != null)
                      ListTile(
                        leading: const Icon(TablerIcons.phone),
                        title: Text(profile.phone!),
                      ),
                    if (membership != null)
                      ListTile(
                        leading: const Icon(TablerIcons.building),
                        title: Text(membership.unitName),
                        subtitle: Text(membership.residentialName),
                      ),
                  ],
                ),
              ),
              if (memberships.length > 1) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(selectedMembershipProvider.notifier).clear(),
                  icon: const Icon(TablerIcons.arrowsHorizontal),
                  label: Text(context.l10n.profileChangeUnit),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                context.l10n.profileAppearance,
                style: context.gatesText.labelSecondary,
              ),
              const SizedBox(height: 8),
              GatesSegmentedTabs<ThemeMode>(
                options: [
                  GatesSegmentedTabOption(
                    value: ThemeMode.light,
                    label: context.l10n.profileThemeLight,
                  ),
                  GatesSegmentedTabOption(
                    value: ThemeMode.dark,
                    label: context.l10n.profileThemeDark,
                  ),
                  GatesSegmentedTabOption(
                    value: ThemeMode.system,
                    label: context.l10n.profileThemeSystem,
                  ),
                ],
                selected: ref.watch(themeModeProvider),
                onSelect: (mode) =>
                    ref.read(themeModeProvider.notifier).select(mode),
              ),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: () => signOutReportingErrors(context, ref),
                icon: const Icon(TablerIcons.logout),
                label: Text(context.l10n.commonLogout),
              ),
            ],
          );
        },
      ),
    );
  }
}

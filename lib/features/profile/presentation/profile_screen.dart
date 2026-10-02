import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_info.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/failure_messages.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/widgets/gates_segmented_tabs.dart';
import '../../../core/widgets/gates_sheet.dart';
import '../../../core/widgets/gates_switch_row.dart';
import '../../../core/widgets/gates_text_action.dart';
import '../../../core/widgets/gates_toast.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../incidents/presentation/photo_picker.dart' show PhotoSource;
import '../../session/presentation/session_controller.dart';
import '../domain/profile.dart';
import 'avatar_picker.dart';
import 'profile_controller.dart';
import 'profile_sheets.dart';
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
          final l10n = context.l10n;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _AvatarHeader(profile: profile),
              if (profile.deletionScheduledFor != null) ...[
                const SizedBox(height: 16),
                _DeletionBanner(date: profile.deletionScheduledFor!),
              ],
              const SizedBox(height: 24),
              _SectionLabel(l10n.profileSectionAccount),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(TablerIcons.user),
                      title: Text(l10n.profileEditName),
                      trailing: const Icon(TablerIcons.pencil),
                      onTap: () => _editName(context, ref, profile),
                    ),
                    ListTile(
                      leading: const Icon(TablerIcons.mail),
                      title: Text(profile.email ?? l10n.profileChangeEmail),
                      trailing: const Icon(TablerIcons.pencil),
                      onTap: () => _changeEmail(context, ref, profile),
                    ),
                    if (profile.phone != null)
                      ListTile(
                        leading: const Icon(TablerIcons.phone),
                        title: Text(profile.phone!),
                      ),
                  ],
                ),
              ),
              if (membership != null) ...[
                const SizedBox(height: 24),
                _SectionLabel(l10n.profileSectionResidence),
                Card(
                  child: ListTile(
                    leading: const Icon(TablerIcons.building),
                    title: Text(membership.unitName),
                    subtitle: Text(membership.residentialName),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.profileUnitManagedNote,
                  style: context.gatesText.caption,
                ),
              ],
              if (memberships.length > 1) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(selectedMembershipProvider.notifier).clear(),
                  icon: const Icon(TablerIcons.arrowsHorizontal),
                  label: Text(l10n.profileChangeUnit),
                ),
              ],
              const SizedBox(height: 24),
              _SectionLabel(l10n.profileSectionSecurity),
              const _BiometricRow(),
              const SizedBox(height: 24),
              _SectionLabel(l10n.profileAppearance),
              GatesSegmentedTabs<ThemeMode>(
                options: [
                  GatesSegmentedTabOption(
                    value: ThemeMode.light,
                    label: l10n.profileThemeLight,
                  ),
                  GatesSegmentedTabOption(
                    value: ThemeMode.dark,
                    label: l10n.profileThemeDark,
                  ),
                  GatesSegmentedTabOption(
                    value: ThemeMode.system,
                    label: l10n.profileThemeSystem,
                  ),
                ],
                selected: ref.watch(themeModeProvider),
                onSelect: (mode) =>
                    ref.read(themeModeProvider.notifier).select(mode),
              ),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: () => _logout(context, ref),
                icon: const Icon(TablerIcons.logout),
                label: Text(l10n.commonLogout),
              ),
              if (profile.deletionScheduledFor == null) ...[
                const SizedBox(height: 8),
                GatesTextAction(
                  label: l10n.profileDeleteAccount,
                  color: context.palette.statusError,
                  onPressed: () => _requestDeletion(context, ref),
                ),
              ],
              const SizedBox(height: 16),
              const _VersionLabel(),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _editName(
  BuildContext context,
  WidgetRef ref,
  Profile profile,
) async {
  final saved = await showEditNameSheet(context, profile);
  if (saved != true || !context.mounted) return;
  showGatesToast(
    context,
    type: GatesToastType.success,
    title: context.l10n.profileSaved,
  );
}

Future<void> _changeEmail(
  BuildContext context,
  WidgetRef ref,
  Profile profile,
) async {
  final changed = await showChangeEmailSheet(context, profile.email);
  if (changed != true || !context.mounted) return;
  showGatesToast(
    context,
    type: GatesToastType.success,
    title: context.l10n.profileEmailChanged,
  );
}

Future<void> _logout(BuildContext context, WidgetRef ref) async {
  final confirmed = await showLogoutConfirmSheet(context);
  if (confirmed != true || !context.mounted) return;
  await signOutReportingErrors(context, ref);
}

Future<void> _requestDeletion(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDeleteAccountSheet(context);
  if (confirmed != true || !context.mounted) return;
  final l10n = context.l10n;
  try {
    final date = await ref
        .read(profileRepositoryProvider)
        .requestAccountDeletion();
    ref.invalidate(myProfileProvider);
    if (!context.mounted) return;
    showGatesToast(
      context,
      type: GatesToastType.success,
      title: l10n.profileDeleteRequested,
      message: l10n.profileDeleteRequestedBody(
        formatProfileDate(context, date),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    showGatesToast(
      context,
      type: GatesToastType.error,
      title: l10n.profileDeleteFailed,
      message: failureDetail(l10n, Failure.from(error)),
    );
  }
}

/// File type of a picked image without the dot, defaulting to jpg.
String _imageExtension(XFile file) {
  final hint = '${file.mimeType ?? ''} ${file.name} ${file.path}'.toLowerCase();
  if (hint.contains('png')) return 'png';
  if (hint.contains('webp')) return 'webp';
  return 'jpg';
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: context.gatesText.labelSecondary),
    );
  }
}

/// Avatar with a camera badge: tapping it asks for camera or gallery,
/// uploads the picked image and refreshes the profile.
class _AvatarHeader extends ConsumerStatefulWidget {
  const _AvatarHeader({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_AvatarHeader> createState() => _AvatarHeaderState();
}

class _AvatarHeaderState extends ConsumerState<_AvatarHeader> {
  bool _uploading = false;

  Future<void> _change() async {
    final source = await showGatesSheet<PhotoSource>(context, (sheetContext) {
      final l10n = sheetContext.l10n;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(TablerIcons.camera),
              title: Text(l10n.profilePhotoCamera),
              onTap: () => Navigator.of(sheetContext).pop(PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(TablerIcons.photo),
              title: Text(l10n.profilePhotoGallery),
              onTap: () => Navigator.of(sheetContext).pop(PhotoSource.gallery),
            ),
          ],
        ),
      );
    });
    if (source == null || !mounted) return;
    final l10n = context.l10n;
    setState(() => _uploading = true);
    try {
      final picked = await ref.read(avatarPickerProvider).pick(source);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final extension = _imageExtension(picked);
      await ref.read(profileRepositoryProvider).uploadAvatar(bytes, extension);
      ref.invalidate(myProfileProvider);
      if (!mounted) return;
      showGatesToast(
        context,
        type: GatesToastType.success,
        title: l10n.profilePhotoUpdated,
      );
    } catch (error) {
      if (!mounted) return;
      showGatesToast(
        context,
        type: GatesToastType.error,
        title: l10n.profilePhotoFailed,
        message: failureDetail(l10n, Failure.from(error)),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final palette = context.palette;
    return Column(
      children: [
        Center(
          child: Semantics(
            button: true,
            label: context.l10n.profileChangePhoto,
            excludeSemantics: true,
            onTap: _uploading ? null : _change,
            child: GestureDetector(
              onTap: _uploading ? null : _change,
              child: SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: palette.bgAccent,
                      foregroundColor: palette.textBrand,
                      foregroundImage: profile.avatarUrl == null
                          ? null
                          : NetworkImage(profile.avatarUrl!),
                      child: _uploading
                          ? const CircularProgressIndicator()
                          : Text(
                              profile.displayName.isNotEmpty
                                  ? profile.displayName[0].toUpperCase()
                                  : '?',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: palette.bgBrand,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: palette.bgSurface,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          TablerIcons.camera,
                          size: 16,
                          color: palette.textOnBrand,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          profile.displayName,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Shown while an account deletion is scheduled, with a way to undo it.
class _DeletionBanner extends ConsumerStatefulWidget {
  const _DeletionBanner({required this.date});

  final DateTime date;

  @override
  ConsumerState<_DeletionBanner> createState() => _DeletionBannerState();
}

class _DeletionBannerState extends ConsumerState<_DeletionBanner> {
  bool _busy = false;

  Future<void> _cancel() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).cancelAccountDeletion();
      ref.invalidate(myProfileProvider);
      if (!mounted) return;
      showGatesToast(
        context,
        type: GatesToastType.success,
        title: l10n.profileDeleteCancelled,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      showGatesToast(
        context,
        type: GatesToastType.error,
        title: l10n.profileDeleteCancelFailed,
        message: failureDetail(l10n, Failure.from(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(GatesSpacing.space16),
      decoration: BoxDecoration(
        color: palette.statusWarningBg,
        borderRadius: BorderRadius.circular(GatesRadius.radius16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.profileDeletePendingTitle, style: GatesTypography.label),
          const SizedBox(height: GatesSpacing.space4),
          Text(
            l10n.profileDeletePendingBody(
              formatProfileDate(context, widget.date),
            ),
            style: GatesTypography.body.copyWith(color: palette.textPrimary),
          ),
          const SizedBox(height: GatesSpacing.space8),
          GatesTextAction(
            label: l10n.profileDeleteCancel,
            filled: true,
            onPressed: _busy ? null : _cancel,
          ),
        ],
      ),
    );
  }
}

class _BiometricRow extends ConsumerWidget {
  const _BiometricRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final enabled = ref.watch(biometricEnabledProvider).value ?? false;
    return GatesSwitchRow(
      label: l10n.profileBiometricTitle,
      description: l10n.profileBiometricDescription,
      value: enabled,
      onChanged: (value) async {
        final controller = ref.read(biometricEnabledProvider.notifier);
        if (!value) {
          await controller.disable();
          return;
        }
        final result = await controller.enable(l10n.profileBiometricReason);
        if (!context.mounted) return;
        switch (result) {
          case BiometricEnableResult.enabled:
            break;
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
      },
    );
  }
}

class _VersionLabel extends ConsumerWidget {
  const _VersionLabel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).value;
    if (version == null) return const SizedBox.shrink();
    return Center(
      child: Text(
        '${context.l10n.profileVersion} · ${context.l10n.profileVersionValue(version)}',
        style: context.gatesText.caption,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../../core/widgets/gates_button.dart';
import '../../../l10n/l10n.dart';
import '../domain/app_status.dart';
import 'status_screen_layout.dart';

/// Shown over the whole app while a platform admin has maintenance mode on.
/// The admin's title/message win over the defaults.
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({
    super.key,
    required this.info,
    required this.onRetry,
  });

  final MaintenanceInfo info;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StatusScreenLayout(
      icon: TablerIcons.tools,
      title: info.title ?? l10n.appStatusMaintenanceTitle,
      body: info.message ?? l10n.appStatusMaintenanceBody,
      actions: [GatesButton(label: l10n.commonRetry, onPressed: onRetry)],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../../core/widgets/gates_button.dart';
import '../../../l10n/l10n.dart';
import 'status_screen_layout.dart';

/// "Revisa tu conexión a internet": shown over the app while the device is
/// offline or the server can't be reached.
class NoConnectionScreen extends StatelessWidget {
  const NoConnectionScreen({
    super.key,
    required this.onRetry,
    this.retrying = false,
  });

  final VoidCallback onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StatusScreenLayout(
      icon: TablerIcons.wifiOff,
      title: l10n.appStatusOfflineTitle,
      body: l10n.appStatusOfflineBody,
      actions: [
        GatesButton(
          label: l10n.commonRetry,
          onPressed: onRetry,
          loading: retrying,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../l10n/l10n.dart';
import '../domain/app_status.dart';
import 'status_screen_layout.dart';

/// Opens the store listing; false when the device can't handle the URL.
typedef StoreLauncher = Future<bool> Function(Uri url);

Future<bool> _launchExternally(Uri url) =>
    launchUrl(url, mode: LaunchMode.externalApplication);

/// "Actualiza la app". A forced release only offers the store button; an
/// optional one adds a "Continuar" button that dismisses it.
class UpdateScreen extends StatefulWidget {
  const UpdateScreen({
    super.key,
    required this.info,
    required this.onContinue,
    this.launcher = _launchExternally,
  });

  final UpdateInfo info;

  /// Dismisses the screen. Only offered when the update isn't forced.
  final VoidCallback onContinue;
  final StoreLauncher launcher;

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  bool _openFailed = false;

  Future<void> _openStore() async {
    var opened = false;
    final uri = Uri.tryParse(widget.info.storeUrl);
    if (uri != null) {
      try {
        opened = await widget.launcher(uri);
      } catch (_) {
        opened = false;
      }
    }
    if (mounted) setState(() => _openFailed = !opened);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final info = widget.info;
    return StatusScreenLayout(
      icon: info.isForced ? TablerIcons.arrowUpCircle : TablerIcons.rocket,
      title:
          info.title ??
          (info.isForced
              ? l10n.appStatusUpdateForcedTitle
              : l10n.appStatusUpdateTitle),
      body:
          info.message ??
          (info.isForced
              ? l10n.appStatusUpdateForcedBody(info.version)
              : l10n.appStatusUpdateBody(info.version)),
      extra: _openFailed
          ? Text(
              l10n.appStatusUpdateOpenFailed,
              style: GatesTypography.body.copyWith(
                color: context.palette.statusError,
              ),
            )
          : null,
      actions: [
        GatesButton(label: l10n.appStatusUpdateAction, onPressed: _openStore),
        if (!info.isForced)
          GatesButton(
            label: l10n.appStatusUpdateContinue,
            style: GatesButtonStyle.secondary,
            onPressed: widget.onContinue,
          ),
      ],
    );
  }
}

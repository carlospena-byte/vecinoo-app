import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../l10n/l10n.dart';

enum GatesToastType { success, info, warning, error }

/// Figma "Toast" (node `33:43`): non-blocking feedback with a status glyph,
/// a title, an optional secondary line and a dismiss button. Every message
/// in the app goes through here instead of a bare [SnackBar].
void showGatesToast(
  BuildContext context, {
  required GatesToastType type,
  required String title,
  String? message,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        duration: const Duration(seconds: 4),
        content: _GatesToast(
          type: type,
          title: title,
          message: message,
          onClose: messenger.hideCurrentSnackBar,
        ),
      ),
    );
}

class _GatesToast extends StatelessWidget {
  const _GatesToast({
    required this.type,
    required this.title,
    required this.onClose,
    this.message,
  });

  final GatesToastType type;
  final String title;
  final String? message;
  final VoidCallback onClose;

  bool get _isError => type == GatesToastType.error;

  Color _background(BuildContext context) => switch (type) {
    GatesToastType.success => context.palette.statusSuccessBg,
    GatesToastType.info => context.palette.bgLilac,
    GatesToastType.warning => context.palette.statusWarningBg,
    GatesToastType.error => context.palette.statusErrorBg,
  };

  String _typeLabel(BuildContext context) => switch (type) {
    GatesToastType.success => context.l10n.commonToastSuccess,
    GatesToastType.info => context.l10n.commonToastInfo,
    GatesToastType.warning => context.l10n.commonToastWarning,
    GatesToastType.error => context.l10n.commonToastError,
  };

  String get _glyph => switch (type) {
    GatesToastType.success => '✓',
    GatesToastType.info || GatesToastType.warning => 'i',
    GatesToastType.error => '!',
  };

  @override
  Widget build(BuildContext context) {
    final accent = _isError
        ? context.palette.statusError
        : context.palette.textBrand;
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(GatesSpacing.space16),
      decoration: BoxDecoration(
        color: _background(context),
        borderRadius: BorderRadius.circular(GatesRadius.radius16),
      ),
      child: Row(
        children: [
          Semantics(
            label: _typeLabel(context),
            child: ExcludeSemantics(
              child: Text(
                _glyph,
                style: GatesTypography.label.copyWith(color: accent),
              ),
            ),
          ),
          const SizedBox(width: GatesSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GatesTypography.label.copyWith(
                    color: _isError
                        ? context.palette.statusError
                        : context.palette.textPrimary,
                  ),
                ),
                if (message != null)
                  Text(message!, style: context.gatesText.caption),
              ],
            ),
          ),
          const SizedBox(width: GatesSpacing.space12),
          Semantics(
            button: true,
            label: context.l10n.commonClose,
            excludeSemantics: true,
            onTap: onClose,
            child: GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GatesSpacing.space8,
                  vertical: GatesSpacing.space4,
                ),
                child: Text(
                  '×',
                  style: GatesTypography.headingSmall.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

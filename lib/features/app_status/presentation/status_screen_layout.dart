import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/vecinoo_brand.dart';

/// Shared frame of the full-screen status views (maintenance, update, no
/// connection): wordmark, a brand icon, a title + body, actions at the
/// bottom. Rendered as an overlay above the router, so it brings its own
/// [Scaffold].
class StatusScreenLayout extends StatelessWidget {
  const StatusScreenLayout({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.actions,
    this.extra,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<Widget> actions;

  /// Optional line under the body (e.g. an inline error).
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.bgSurface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const VecinooWordmark(),
              Expanded(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 320),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.palette.bgAccent,
                          ),
                          child: Icon(
                            icon,
                            size: 40,
                            color: context.palette.textBrand,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: GatesTypography.headingLarge,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          body,
                          style: GatesTypography.body.copyWith(
                            color: context.palette.textSecondary,
                          ),
                        ),
                        if (extra != null) ...[
                          const SizedBox(height: 12),
                          extra!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                actions[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

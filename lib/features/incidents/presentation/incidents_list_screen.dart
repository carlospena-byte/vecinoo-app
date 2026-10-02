import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_add_button.dart';
import '../../../core/widgets/gates_segmented_tabs.dart';
import '../../../core/paging/paged_notifier.dart';
import '../../../core/widgets/gates_paged_list.dart';
import '../../../core/widgets/nav_clearance.dart';
import '../../../core/widgets/state_views.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/incident.dart';
import '../../../l10n/l10n.dart';
import 'incident_labels.dart';
import 'incidents_controller.dart';

String _emptyMessage(AppLocalizations l10n, IncidentGroup tab) => switch (tab) {
  IncidentGroup.pending => l10n.incidentsListEmptyPending,
  IncidentGroup.inProgress => l10n.incidentsListEmptyInProgress,
  IncidentGroup.history => l10n.incidentsListEmptyHistory,
};

final _dateFormat = DateFormat('d MMM y, HH:mm', 'es');

/// "Incidencias" tab — same shape as the Reservas and Visitas tabs: header
/// with a "+" that starts a new report, then Pendientes / En curso /
/// Historial. Lives inside [HomeShell]'s tab shell, so it has no app bar or
/// bottom navigation of its own.
class IncidentsListScreen extends ConsumerStatefulWidget {
  const IncidentsListScreen({super.key});

  @override
  ConsumerState<IncidentsListScreen> createState() =>
      _IncidentsListScreenState();
}

class _IncidentsListScreenState extends ConsumerState<IncidentsListScreen> {
  IncidentGroup _tab = IncidentGroup.pending;

  /// Back from the report flow or a detail: anything may have changed
  /// (status, new report), so every tab starts over and the Home summary
  /// refetches.
  void _reload(String residentialId) {
    ref.invalidate(incidentsListProvider(residentialId));
    for (final group in IncidentGroup.values) {
      ref.invalidate(incidentsPagingProvider((residentialId, group)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final membership = ref.watch(selectedMembershipProvider).value;
    if (membership == null) return const LoadingView();

    final residentialId = membership.residentialId;
    final key = (residentialId, _tab);
    final paging = ref.watch(incidentsPagingProvider(key));
    final controller = ref.read(incidentsPagingProvider(key).notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GatesSpacing.space24,
                GatesSpacing.space16,
                GatesSpacing.space24,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.incidentsListTitle,
                      style: GatesTypography.headingMedium,
                    ),
                  ),
                  GatesAddButton(
                    semanticLabel: context.l10n.incidentsReportAction,
                    onTap: () async {
                      await context.push('/incidents/report');
                      _reload(residentialId);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GatesSpacing.space24,
                GatesSpacing.space16,
                GatesSpacing.space24,
                0,
              ),
              child: GatesSegmentedTabs<IncidentGroup>(
                options: [
                  GatesSegmentedTabOption(
                    value: IncidentGroup.pending,
                    label: context.l10n.incidentsTabPending,
                  ),
                  GatesSegmentedTabOption(
                    value: IncidentGroup.inProgress,
                    label: context.l10n.incidentsTabInProgress,
                  ),
                  GatesSegmentedTabOption(
                    value: IncidentGroup.history,
                    label: context.l10n.incidentsTabHistory,
                  ),
                ],
                selected: _tab,
                onSelect: (tab) => setState(() => _tab = tab),
              ),
            ),
            Expanded(
              child: paging.items.isEmpty
                  ? _emptyBody(context, paging, controller)
                  : GatesPagedList<Incident>(
                      items: paging.items,
                      state: paging,
                      onLoadMore: controller.loadMore,
                      onRefresh: controller.refresh,
                      padding: EdgeInsets.fromLTRB(
                        GatesSpacing.space24,
                        GatesSpacing.space16,
                        GatesSpacing.space24,
                        homeNavClearance(context),
                      ),
                      itemBuilder: (context, incident) => _IncidentCard(
                        incident: incident,
                        onTap: () async {
                          await context.push('/incidents/${incident.id}');
                          _reload(residentialId);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// No items yet: the first load, its failure, or an empty tab.
  Widget _emptyBody(
    BuildContext context,
    PagedState<Incident> paging,
    IncidentsPagingController controller,
  ) {
    if (paging.failure != null) {
      return ErrorView(
        message: context.l10n.incidentsListLoadError,
        onRetry: controller.refresh,
      );
    }
    if (paging.loading) return const LoadingView();
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: EmptyView(
              message: _emptyMessage(context.l10n, _tab),
              icon: TablerIcons.flagExclamation,
            ),
          ),
        ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident, required this.onTap});

  final Incident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(GatesSpacing.space16),
        decoration: BoxDecoration(
          color: context.palette.bgSurface,
          border: Border.all(color: context.palette.borderDefault),
          borderRadius: BorderRadius.circular(GatesRadius.radius16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              incident.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GatesTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
            if (incident.incidentTypeName != null) ...[
              const SizedBox(height: GatesSpacing.space4),
              Text(
                incident.incidentTypeName!,
                style: context.gatesText.caption,
              ),
            ],
            const SizedBox(height: GatesSpacing.space4),
            Text(
              _dateFormat.format(incident.createdAt).replaceAll('.', ''),
              style: context.gatesText.labelSecondary,
            ),
            const SizedBox(height: GatesSpacing.space12),
            IncidentStatusBadge(status: incident.status),
          ],
        ),
      ),
    );
  }
}

class IncidentStatusBadge extends StatelessWidget {
  const IncidentStatusBadge({super.key, required this.status});

  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      IncidentStatus.newIncident => (
        context.palette.statusWarningBg,
        context.palette.statusWarning,
      ),
      IncidentStatus.inProgress => (
        context.palette.bgAccent,
        context.palette.textBrand,
      ),
      IncidentStatus.resolved => (
        context.palette.statusSuccessBg,
        context.palette.statusSuccess,
      ),
      IncidentStatus.closed || IncidentStatus.cancelled => (
        context.palette.bgSubtle,
        context.palette.textSecondary,
      ),
    };
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: GatesSpacing.space8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(GatesRadius.radius8),
      ),
      alignment: Alignment.center,
      child: Text(
        incidentStatusLabel(context.l10n, status),
        style: context.gatesText.caption.copyWith(color: foreground),
      ),
    );
  }
}

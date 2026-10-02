import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/failure_messages.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_full_width_image.dart';
import '../../../core/widgets/gates_html.dart';
import '../../../core/widgets/gates_sheet.dart';
import '../../../core/widgets/gates_text_action.dart';
import '../../../core/widgets/gates_toast.dart';
import '../../session/presentation/session_controller.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/incident.dart';
import '../../../l10n/l10n.dart';
import '../../auth/presentation/auth_controller.dart';
import 'incident_edit_args.dart';
import 'incidents_controller.dart';
import 'incidents_list_screen.dart' show IncidentStatusBadge;

final _dateFormat = DateFormat("d 'de' MMMM y, HH:mm", 'es');

/// Detail of one report, reached from the Incidencias list. The reporter gets
/// "Editar" / "Cancelar" here while the incident is still new (Figma I14 /
/// I15: "Acceso desde el detalle, según los estados que permita el backend").
class IncidentDetailScreen extends ConsumerWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentAsync = ref.watch(incidentDetailProvider(incidentId));
    final attachments = ref.watch(incidentAttachmentsProvider(incidentId));
    final userId = ref.watch(currentUserProvider)?.id;

    return incidentAsync.when(
      loading: () => _shell(context, const LoadingView()),
      error: (e, _) => _shell(
        context,
        ErrorView(
          message: context.l10n.incidentsDetailLoadError,
          onRetry: () => ref.invalidate(incidentDetailProvider(incidentId)),
        ),
      ),
      data: (incident) {
        final canManage = incident.isEditable && incident.reportedBy == userId;
        return _shell(
          context,
          SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.only(bottom: GatesSpacing.space24),
              children: [
                _IncidentContent(
                  incident: incident,
                  photos: attachments.value ?? const [],
                ),
              ],
            ),
          ),
          bottom: canManage
              ? SafeArea(
                  minimum: const EdgeInsets.all(GatesSpacing.space24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GatesTextAction(
                        label: context.l10n.incidentsEditAction,
                        filled: true,
                        onPressed: () async {
                          final photos = await ref.read(
                            incidentAttachmentsProvider(incidentId).future,
                          );
                          if (!context.mounted) return;
                          await context.push(
                            '/incidents/$incidentId/edit',
                            extra: IncidentEditArgs(
                              incident: incident,
                              attachments: photos,
                            ),
                          );
                          ref.invalidate(incidentDetailProvider(incidentId));
                          ref.invalidate(
                            incidentAttachmentsProvider(incidentId),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      GatesTextAction(
                        label: context.l10n.incidentsCancelAction,
                        color: context.palette.statusError,
                        onPressed: () => _confirmCancel(context, ref),
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }

  /// Figma I15, presented as the standard Gates confirmation bottom sheet
  /// (same as cancelling an invitation). The report stays in the history as
  /// "Cancelada".
  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    // Read before the sheet opens: the sheet keeps rebuilding while it
    // animates out, by which time [context] may already be popped.
    final l10n = context.l10n;
    final confirmed = await showGatesSheet<bool>(
      context,
      (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: GatesSpacing.space24)
            .copyWith(bottom: GatesSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GatesSheetHeader(title: l10n.incidentsCancelAction),
            const SizedBox(height: GatesSpacing.space8),
            Text(l10n.incidentsCancelSheetBody, style: GatesTypography.body),
            const SizedBox(height: GatesSpacing.space24),
            SizedBox(
              width: double.infinity,
              child: GatesButton(
                label: l10n.incidentsCancelConfirm,
                style: GatesButtonStyle.destructive,
                onPressed: () => Navigator.of(sheetContext).pop(true),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(incidentsRepositoryProvider).cancelIncident(incidentId);
      final membership = ref.read(selectedMembershipProvider).value;
      if (membership != null) {
        ref.invalidate(incidentsListProvider(membership.residentialId));
      }
      ref.invalidate(incidentDetailProvider(incidentId));
      if (!context.mounted) return;
      context.pop();
      showGatesToast(
        context,
        type: GatesToastType.success,
        title: context.l10n.incidentsCancelledToast,
      );
    } catch (error) {
      if (!context.mounted) return;
      final detail = failureDetail(context.l10n, Failure.from(error));
      showGatesToast(
        context,
        type: GatesToastType.error,
        title: context.l10n.incidentsCancelFailedTitle,
        message: detail == null
            ? context.l10n.incidentsTryAgain
            : '$detail ${context.l10n.incidentsTryAgain}',
      );
    }
  }

  Widget _shell(BuildContext context, Widget body, {Widget? bottom}) =>
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(context.l10n.incidentsDetailTitle),
        ),
        body: body,
        bottomNavigationBar: bottom,
      );
}

/// The report laid out edge to edge: text with the page margins, photos at
/// the full screen width (tap to zoom).
class _IncidentContent extends StatelessWidget {
  const _IncidentContent({required this.incident, required this.photos});

  final Incident incident;
  final List<IncidentAttachment> photos;

  @override
  Widget build(BuildContext context) {
    final description = incident.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GatesSpacing.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.incidentsDetailReportedOn(
                  _dateFormat.format(incident.createdAt),
                ),
                style: context.gatesText.caption,
              ),
              const SizedBox(height: GatesSpacing.space4),
              Text(
                incident.title,
                style: GatesTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: GatesSpacing.space12,
                runSpacing: GatesSpacing.space8,
                children: [
                  IncidentStatusBadge(status: incident.status),
                  if (incident.incidentTypeName != null)
                    Text(
                      incident.incidentTypeName!,
                      style: context.gatesText.labelSecondary,
                    ),
                ],
              ),
              if (description != null && description.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  context.l10n.incidentsDetailDescription,
                  style: context.gatesText.caption,
                ),
                const SizedBox(height: GatesSpacing.space4),
                GatesHtml(description),
              ],
            ],
          ),
        ),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 20),
          for (final (i, photo) in photos.indexed) ...[
            if (i > 0) const SizedBox(height: GatesSpacing.space8),
            GatesFullWidthImage(
              url: photo.url,
              semanticLabel: context.l10n.incidentsAttachedPhoto,
              semanticHint: context.l10n.incidentsAttachedPhotoHint,
            ),
          ],
        ],
      ],
    );
  }
}

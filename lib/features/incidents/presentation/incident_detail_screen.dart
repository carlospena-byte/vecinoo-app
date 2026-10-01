import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_sheet.dart';
import '../../../core/widgets/gates_text_action.dart';
import '../../../core/widgets/gates_toast.dart';
import '../../session/presentation/session_controller.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/incident.dart';
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
    final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;

    return incidentAsync.when(
      loading: () => _shell(const LoadingView()),
      error: (e, _) => _shell(
        ErrorView(
          message: 'No se pudo cargar la incidencia.',
          onRetry: () => ref.invalidate(incidentDetailProvider(incidentId)),
        ),
      ),
      data: (incident) {
        final canManage = incident.isEditable && incident.reportedBy == userId;
        return _shell(
          SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.all(GatesSpacing.space24)
                  .copyWith(top: 0),
              children: [
                _SummaryCard(
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
                        label: 'Editar incidencia',
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
                        label: 'Cancelar incidencia',
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
    final confirmed = await showGatesSheet<bool>(
      context,
      (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: GatesSpacing.space24)
            .copyWith(bottom: GatesSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GatesSheetHeader(title: 'Cancelar incidencia'),
            const SizedBox(height: GatesSpacing.space8),
            Text(
              'Ya no se le dará seguimiento. La incidencia seguirá en tu '
              'historial como cancelada.',
              style: GatesTypography.body,
            ),
            const SizedBox(height: GatesSpacing.space24),
            SizedBox(
              width: double.infinity,
              child: GatesButton(
                label: 'Sí, cancelar incidencia',
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
        title: 'Incidencia cancelada',
      );
    } catch (_) {
      if (!context.mounted) return;
      showGatesToast(
        context,
        type: GatesToastType.error,
        title: 'No pudimos cancelar la incidencia',
        message: 'Intenta de nuevo.',
      );
    }
  }

  Widget _shell(Widget body, {Widget? bottom}) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      title: const Text('Incidencia'),
    ),
    body: body,
    bottomNavigationBar: bottom,
  );
}

/// Same card shape as the invitation's "Resumen y estado" (Figma 402:1939).
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.incident, required this.photos});

  final Incident incident;
  final List<IncidentAttachment> photos;

  @override
  Widget build(BuildContext context) {
    final description = incident.description;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        border: Border.all(color: context.palette.borderDefault),
        borderRadius: BorderRadius.circular(GatesRadius.radius16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reportada el ${_dateFormat.format(incident.createdAt)}',
            style: context.gatesText.caption.copyWith(fontSize: 13),
          ),
          const SizedBox(height: GatesSpacing.space4),
          Text(
            incident.title,
            style: GatesTypography.body.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 26 / 18,
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
            Text('Descripción', style: context.gatesText.caption),
            const SizedBox(height: GatesSpacing.space4),
            Html(
              data: description,
              onLinkTap: (url, _, _) {
                final uri = url == null ? null : Uri.tryParse(url);
                if (uri != null) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              style: {
                'body': Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontFamily: 'Manrope',
                  fontSize: FontSize(14),
                  lineHeight: const LineHeight(21 / 14),
                  color: context.palette.textPrimary,
                ),
                'p': Style(margin: Margins.only(bottom: 4)),
                'ul': Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.only(left: 16),
                ),
                'li': Style(padding: HtmlPaddings.zero),
                'a': Style(color: context.palette.textBrand),
              },
            ),
          ],
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Fotografías', style: context.gatesText.caption),
            const SizedBox(height: GatesSpacing.space8),
            Wrap(
              spacing: GatesSpacing.space12,
              runSpacing: GatesSpacing.space12,
              children: [for (final a in photos) _AttachmentThumb(url: a.url)],
            ),
          ],
        ],
      ),
    );
  }
}

class _AttachmentThumb extends StatelessWidget {
  const _AttachmentThumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Fotografía adjunta',
      hint: 'Toca dos veces para ampliar',
      child: GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(GatesSpacing.space16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(GatesRadius.radius16),
              child: InteractiveViewer(child: Image.network(url)),
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            width: 104,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 104,
              height: 100,
              color: context.palette.bgSubtle,
              child: Icon(
                Icons.broken_image_outlined,
                color: context.palette.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

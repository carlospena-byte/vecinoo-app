import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure_messages.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_select_field.dart';
import '../../../core/widgets/gates_sheet.dart';
import '../../../core/widgets/gates_text_field.dart';
import '../../../core/widgets/gates_toast.dart';
import '../../../l10n/l10n.dart';
import '../domain/incident.dart';
import '../../session/presentation/session_controller.dart';
import 'incident_edit_args.dart';
import 'incident_rich_editor.dart';
import 'incidents_controller.dart';
import 'photo_picker.dart';
import 'report_incident_controller.dart';
import 'report_incident_photos.dart';

/// "15 · Incidencias / Crear reporte" — Figma nodes I01/I03 (form), I04
/// (photo source sheet), I06 (photo upload error), I07 (sending) and I08
/// (sent). One screen renders all of them from [ReportPhase]; the flow
/// itself lives in [ReportIncidentController].
class ReportIncidentScreen extends ConsumerStatefulWidget {
  const ReportIncidentScreen({super.key, this.editing});

  /// When set, the form is prefilled from this incident and saving updates
  /// it instead of creating a new one (Figma I14).
  final IncidentEditArgs? editing;

  @override
  ConsumerState<ReportIncidentScreen> createState() =>
      _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends ConsumerState<ReportIncidentScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = RichTextController();
  StreamSubscription<ReportEvent>? _events;

  bool get _isEditing => widget.editing != null;

  ReportIncidentController get _controller =>
      ref.read(reportIncidentControllerProvider(widget.editing).notifier);

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _titleController.text = editing.incident.title;
      _descriptionController.loadHtml(editing.incident.description);
    }
    _controller.markLoadedDraft(
      title: _titleController.text,
      description: _descriptionController.text,
    );
    _events = _controller.events.listen(_onEvent);
    _titleController.addListener(_syncDraft);
    _descriptionController.addListener(_syncDraft);
  }

  @override
  void dispose() {
    _events?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _syncDraft() => _controller.updateDraft(
    title: _titleController.text,
    description: _descriptionController.text,
  );

  /// Leaving with unsaved edits asks for confirmation (edit mode only).
  bool _confirmsExit(ReportIncidentState s) =>
      _isEditing && s.phase == ReportPhase.form && s.isDirty;

  void _onEvent(ReportEvent event) {
    if (!mounted) return;
    final l10n = context.l10n;
    switch (event) {
      case PhotoLimitReached(:final added):
        showGatesToast(
          context,
          type: GatesToastType.info,
          title: l10n.incidentsReportMaxPhotos(maxIncidentPhotos),
          message: l10n.incidentsReportAddedFirst(added),
        );
      case PhotosOpenFailed():
        showGatesToast(
          context,
          type: GatesToastType.error,
          title: l10n.incidentsReportPhotosOpenFailed,
          message: l10n.incidentsReportPhotosPermissions,
        );
      case SaveFailed(:final failure):
        showGatesToast(
          context,
          type: GatesToastType.error,
          title: l10n.incidentsReportSaveFailed,
          message: _withDetail(
            failureDetail(l10n, failure),
            l10n.incidentsReportSaveFailedBody,
          ),
        );
      case SendFailed(:final failure):
        showGatesToast(
          context,
          type: GatesToastType.error,
          title: l10n.incidentsReportSendFailed,
          message: _withDetail(
            failureDetail(l10n, failure),
            l10n.incidentsReportSendFailedBody,
          ),
        );
      case EditSaved():
        context.pop();
        showGatesToast(
          context,
          type: GatesToastType.success,
          title: l10n.incidentsReportChangesSaved,
        );
    }
  }

  String _withDetail(String? detail, String fallback) =>
      detail == null ? fallback : '$detail $fallback';

  Future<void> _pickPhotos() async {
    if (ref
            .read(reportIncidentControllerProvider(widget.editing))
            .photos
            .length >=
        maxIncidentPhotos) {
      return;
    }
    final source = await _showPhotoSourceSheet();
    if (source == null || !mounted) return;
    await _controller.addPhotos(source);
  }

  Future<PhotoSource?> _showPhotoSourceSheet() {
    return showModalBottomSheet<PhotoSource>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: context.palette.scrim,
      builder: (sheetContext) => PhotoSourceSheet(
        onPick: (source) => Navigator.of(sheetContext).pop(source),
        onCancel: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }

  Future<void> _submit() => _controller.submit(
    title: _titleController.text,
    descriptionHtml: _descriptionController.toHtml(),
  );

  Future<void> _confirmDiscard() async {
    final discard = await showGatesSheet<bool>(
      context,
      (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: GatesSpacing.space24)
            .copyWith(bottom: GatesSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GatesSheetHeader(title: context.l10n.incidentsReportDiscardTitle),
            const SizedBox(height: GatesSpacing.space8),
            Text(
              context.l10n.incidentsReportDiscardBody,
              style: GatesTypography.body,
            ),
            const SizedBox(height: GatesSpacing.space24),
            GatesButton(
              label: context.l10n.incidentsReportDiscardAction,
              style: GatesButtonStyle.destructive,
              onPressed: () => Navigator.of(sheetContext).pop(true),
            ),
            const SizedBox(height: GatesSpacing.space8),
            GatesButton(
              label: context.l10n.incidentsReportKeepEditing,
              style: GatesButtonStyle.secondary,
              onPressed: () => Navigator.of(sheetContext).pop(false),
            ),
          ],
        ),
      ),
    );
    if (discard == true && mounted) context.pop();
  }

  void _goHome() => context.go('/');

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(reportIncidentControllerProvider(widget.editing));
    return PopScope(
      canPop: s.phase != ReportPhase.sending && !_confirmsExit(s),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _confirmsExit(s)) _confirmDiscard();
      },
      child: switch (s.phase) {
        ReportPhase.form => _buildForm(context, s),
        ReportPhase.sending => _buildSending(context, s),
        ReportPhase.photoError => _buildPhotoError(context, s),
        ReportPhase.sent => _buildSent(context, s),
      },
    );
  }

  // ---------------------------------------------------------------- form

  Widget _buildForm(BuildContext context, ReportIncidentState s) {
    final membership = ref.watch(selectedMembershipProvider).value;
    final types = membership == null
        ? const <IncidentType>[]
        : ref.watch(incidentTypesProvider(membership.residentialId)).value ??
              const <IncidentType>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          _isEditing
              ? context.l10n.incidentsReportEditTitle
              : context.l10n.incidentsReportAction,
          style: _appBarTitle,
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            GatesSpacing.space24,
            0,
            GatesSpacing.space24,
            GatesSpacing.space24,
          ),
          children: [
            Text(
              context.l10n.incidentsReportIntro,
              style: context.gatesText.labelSecondary,
            ),
            const SizedBox(height: GatesSpacing.space16),
            GatesSelectField<String>(
              label: context.l10n.incidentsReportCategoryLabel,
              placeholder: context.l10n.incidentsReportCategoryPlaceholder,
              value: s.incidentTypeId ?? '',
              options: {for (final t in types) t.id: t.name},
              onChanged: _controller.selectType,
            ),
            const SizedBox(height: GatesSpacing.space16),
            GatesTextField(
              controller: _titleController,
              label: context.l10n.incidentsReportTitleLabel,
              hintText: context.l10n.incidentsReportTitleHint,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: GatesSpacing.space16),
            IncidentRichEditor(controller: _descriptionController),
            const SizedBox(height: GatesSpacing.space16),
            PhotosSection(
              photos: s.photos,
              onAdd: _pickPhotos,
              onRemove: (photo) => _controller.removePhoto(photo.id),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _FixedAction(
        child: ListenableBuilder(
          listenable: _titleController,
          builder: (context, _) => GatesButton(
            label: _isEditing
                ? context.l10n.incidentsReportSaveChanges
                : context.l10n.incidentsReportAction,
            onPressed: _titleController.text.trim().isEmpty ? null : _submit,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- sending

  Widget _buildSending(BuildContext context, ReportIncidentState s) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(context.l10n.incidentsReportAction, style: _appBarTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(GatesSpacing.space24).copyWith(top: 0),
        children: [
          Text(
            _isEditing
                ? context.l10n.incidentsReportSavingChanges
                : context.l10n.incidentsReportSending,
            style: GatesTypography.headingMedium,
          ),
          const SizedBox(height: GatesSpacing.space16),
          Text(
            context.l10n.incidentsReportWaitMessage,
            style: context.gatesText.labelSecondary,
          ),
          const SizedBox(height: GatesSpacing.space16),
          PhotosSection(photos: s.photos, showAdd: false),
        ],
      ),
      bottomNavigationBar: _FixedAction(
        child: GatesButton(
          label: context.l10n.incidentsReportSendingButton,
          onPressed: null,
        ),
      ),
    );
  }

  // --------------------------------------------------------- photo error

  Widget _buildPhotoError(BuildContext context, ReportIncidentState s) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(context.l10n.incidentsDetailPhotos, style: _appBarTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(GatesSpacing.space24).copyWith(top: 0),
        children: [
          if (s.hasPhotoErrors) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(GatesSpacing.space16),
              decoration: BoxDecoration(
                color: context.palette.statusErrorBg,
                borderRadius: BorderRadius.circular(GatesRadius.radius16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.incidentsReportPhotoErrorTitle,
                    style: GatesTypography.label.copyWith(
                      color: context.palette.statusError,
                    ),
                  ),
                  const SizedBox(height: GatesSpacing.space8),
                  Text(
                    context.l10n.incidentsReportPhotoErrorBody,
                    style: context.gatesText.labelSecondary.copyWith(
                      color: context.palette.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: GatesSpacing.space16),
          ],
          PhotosSection(
            photos: s.photos,
            onAdd: _pickPhotos,
            onRemove: (photo) => _controller.removePhoto(photo.id),
            onRetry: (_) => _controller.uploadPending(),
            removableStatuses: const {PhotoStatus.error},
          ),
          if (s.hasPhotoErrors) ...[
            const SizedBox(height: GatesSpacing.space16),
            GatesButton(
              label: context.l10n.incidentsReportRetryPhoto,
              style: GatesButtonStyle.secondary,
              onPressed: _controller.uploadPending,
            ),
          ],
        ],
      ),
      bottomNavigationBar: _FixedAction(
        child: GatesButton(
          label: context.l10n.incidentsReportDone,
          onPressed: s.hasPhotoErrors ? null : _controller.finish,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- sent

  Widget _buildSent(BuildContext context, ReportIncidentState s) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: BackButton(onPressed: _goHome),
          title: Text(
            context.l10n.incidentsReportSentTitle,
            style: _appBarTitle,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(GatesSpacing.space24).copyWith(top: 0),
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: context.palette.statusSuccessBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 24,
                    color: context.palette.textBrand,
                  ),
                ),
                const SizedBox(width: GatesSpacing.space16),
                Expanded(
                  child: Text(
                    context.l10n.incidentsReportSentHeadline,
                    style: GatesTypography.headingMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: GatesSpacing.space16),
            Text(
              context.l10n.incidentsReportSentBody,
              style: GatesTypography.body.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
            const SizedBox(height: GatesSpacing.space16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.palette.bgSurface,
                borderRadius: BorderRadius.circular(GatesRadius.radius16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.sentTitle, style: GatesTypography.headingSmall),
                  if (s.sentCategory != null) ...[
                    const SizedBox(height: GatesSpacing.space12),
                    Text(
                      s.sentCategory!,
                      style: context.gatesText.labelSecondary,
                    ),
                  ],
                  const SizedBox(height: GatesSpacing.space12),
                  Text(
                    context.l10n.incidentsReportReceived,
                    style: GatesTypography.label.copyWith(
                      color: context.palette.statusSuccess,
                    ),
                  ),
                  const SizedBox(height: GatesSpacing.space12),
                  Row(
                    children: [
                      Text(
                        context.l10n.incidentsDetailPhotos,
                        style: context.gatesText.labelSecondary,
                      ),
                      const SizedBox(width: GatesSpacing.space12),
                      Text(
                        '${s.uploadedCount} / $maxIncidentPhotos',
                        style: context.gatesText.labelSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _FixedAction(
          child: GatesButton(
            label: context.l10n.incidentsReportBackHome,
            onPressed: _goHome,
          ),
        ),
      ),
    );
  }
}

/// AppBar title in the Figma AppBar: Heading/Small (20 / semibold).
final _appBarTitle = GatesTypography.headingSmall;

/// Figma "Acción fija": white bar pinned above the system inset holding the
/// primary button.
class _FixedAction extends StatelessWidget {
  const _FixedAction({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.palette.bgSurface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: GatesSpacing.space24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            GatesSpacing.space24,
            GatesSpacing.space12,
            GatesSpacing.space24,
            0,
          ),
          child: child,
        ),
      ),
    );
  }
}

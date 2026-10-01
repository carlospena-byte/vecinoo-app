import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/error/failure_messages.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_sheet.dart';
import '../../../core/widgets/gates_toast.dart';
import '../../../l10n/l10n.dart';
import '../../home/home_shell.dart';
import '../domain/visit.dart';
import 'create_frequent_visit_controller.dart';
import 'frequent_visit_form_steps.dart';

/// Acceso frecuente flow — Figma "09 · Visitas / Acceso frecuente"
/// (node 116:185). Two steps in one screen: R01 "Datos de la visita" (name,
/// type, phone, ID document, vehicle) and R02/R03 "Días y horario" (frequency,
/// schedule or custom blocks, notes, arrival alert). The back arrow steps back
/// to R01 before leaving the flow.
class CreateFrequentVisitScreen extends ConsumerStatefulWidget {
  const CreateFrequentVisitScreen({super.key, this.editing});

  /// When set, the form is prefilled from this frequent visit and saving
  /// updates it instead of creating a new one.
  final Visit? editing;

  @override
  ConsumerState<CreateFrequentVisitScreen> createState() =>
      _CreateFrequentVisitScreenState();
}

class _CreateFrequentVisitScreenState
    extends ConsumerState<CreateFrequentVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _plateController = TextEditingController();
  final _notesController = TextEditingController();
  StreamSubscription<CreateFrequentVisitEvent>? _events;

  CreateFrequentVisitController get _controller =>
      ref.read(createFrequentVisitControllerProvider(widget.editing).notifier);

  @override
  void initState() {
    super.initState();
    _events = _controller.events.listen(_onEvent);
    final visit = widget.editing;
    if (visit == null) return;
    _nameController.text = visit.name ?? '';
    _phoneController.text = splitFrequentPhone(visit.phone).local;
    _plateController.text = visit.plate ?? '';
    _notesController.text = visit.notes ?? '';
  }

  @override
  void dispose() {
    _events?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _plateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onEvent(CreateFrequentVisitEvent event) {
    if (!mounted) return;
    final l10n = context.l10n;
    switch (event) {
      case FrequentVisitInvalid(:final issue):
        showGatesToast(
          context,
          type: GatesToastType.warning,
          title: l10n.visitsFrequentMissingData,
          message: switch (issue) {
            FrequentVisitIssue.eachBlockNeedsDay =>
              l10n.visitsFrequentSelectDayEachBlock,
            FrequentVisitIssue.startBeforeEnd =>
              l10n.visitsFrequentStartBeforeEnd,
          },
        );
      case FrequentVisitSaved(:final updated):
        if (updated) {
          showGatesToast(
            context,
            type: GatesToastType.success,
            title: l10n.visitsFrequentUpdatedToast,
          );
          context.pop();
        } else {
          showGatesToast(
            context,
            type: GatesToastType.success,
            title: l10n.visitsFrequentAuthorizedToast,
          );
          context.go('/', extra: const HomeTabRequest(HomeShell.visitsTab));
        }
      case FrequentVisitSaveFailed(:final failure):
        final detail = failureDetail(l10n, failure);
        showGatesToast(
          context,
          type: GatesToastType.error,
          title: widget.editing != null
              ? l10n.visitsSaveError
              : l10n.visitsFrequentAuthorizeError,
          message: detail == null
              ? l10n.visitsTryAgain
              : '$detail ${l10n.visitsTryAgain}',
        );
    }
  }

  Future<void> _pickDocument() async {
    final source = await showGatesSheet<ImageSource>(
      context,
      (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: GatesSpacing.space24)
            .copyWith(bottom: GatesSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GatesSheetHeader(title: context.l10n.visitsFrequentIdDocument),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(TablerIcons.camera),
              title: Text(
                context.l10n.visitsFrequentTakePhoto,
                style: GatesTypography.body,
              ),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(TablerIcons.photo),
              title: Text(
                context.l10n.visitsFrequentPickGallery,
                style: GatesTypography.body,
              ),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
    );
    if (picked == null || !mounted) return;
    await _controller.setDocument(picked);
  }

  void _continue() =>
      _controller.next(formValid: _formKey.currentState?.validate() ?? false);

  void _submit() => _controller.submit(
    name: _nameController.text,
    phoneDigits: _phoneController.text,
    plate: _plateController.text,
    notes: _notesController.text,
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      createFrequentVisitControllerProvider(widget.editing),
    );
    final controller = _controller;
    final isFirstStep = state.step == 0;
    final isEditing = widget.editing != null;
    return PopScope(
      canPop: isFirstStep || state.isSubmitting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.backToFirstStep();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            isFirstStep
                ? context.l10n.visitsFrequentAccess
                : context.l10n.visitsFrequentDaysAndHours,
          ),
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                GatesSpacing.space24,
                GatesSpacing.space8,
                GatesSpacing.space24,
                GatesSpacing.space24,
              ),
              children: [
                Text(
                  isFirstStep
                      ? context.l10n.visitsFrequentStep1
                      : context.l10n.visitsFrequentStep2,
                  style: context.gatesText.caption,
                ),
                const SizedBox(height: GatesSpacing.space16),
                if (isFirstStep)
                  FrequentDataStep(
                    state: state,
                    controller: controller,
                    nameController: _nameController,
                    phoneController: _phoneController,
                    plateController: _plateController,
                    onPickDocument: _pickDocument,
                  )
                else
                  FrequentScheduleStep(
                    state: state,
                    controller: controller,
                    notesController: _notesController,
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(GatesSpacing.space24),
          child: GatesButton(
            label: isFirstStep
                ? context.l10n.visitsContinue
                : (isEditing
                      ? context.l10n.visitsSaveChanges
                      : context.l10n.visitsFrequentAuthorize),
            loading: state.isSubmitting,
            onPressed: state.isSubmitting
                ? null
                : (isFirstStep ? _continue : _submit),
          ),
        ),
      ),
    );
  }
}

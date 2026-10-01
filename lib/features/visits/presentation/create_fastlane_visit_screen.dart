import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_calendar.dart';
import '../../../core/widgets/gates_text_area.dart';
import '../../../core/widgets/gates_tap_field.dart';
import '../../../core/widgets/gates_text_field.dart';
import '../../../core/widgets/gates_toast.dart';
import '../../../core/widgets/gates_time_picker.dart';
import '../../../l10n/l10n.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/visit.dart';
import 'create_fastlane_visit_controller.dart';
import 'frequent_visit_formatters.dart';
import 'visit_date_formatters.dart';
import 'visit_failure_text.dart';

const _notesMaxLength = 120;

/// FastLane invite flow — Figma "10 · Visitas / FastLane residente"
/// (node 116:186). F01 asks for a reference name, visit date and expected
/// arrival time; on success it swaps in F02, showing the self-registration
/// link the resident shares themselves via the OS share sheet (F03) instead
/// of a backend-sent SMS/WhatsApp message.
class CreateFastlaneVisitScreen extends ConsumerStatefulWidget {
  const CreateFastlaneVisitScreen({super.key, this.editing});

  /// When set, the form is prefilled from this pending invitation and saving
  /// updates it instead of creating a new one.
  final Visit? editing;

  @override
  ConsumerState<CreateFastlaneVisitScreen> createState() =>
      _CreateFastlaneVisitScreenState();
}

class _CreateFastlaneVisitScreenState
    extends ConsumerState<CreateFastlaneVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  StreamSubscription<CreateFastlaneVisitEvent>? _events;

  bool get _isEditing => widget.editing != null;

  CreateFastlaneVisitController get _controller =>
      ref.read(createFastlaneVisitControllerProvider(widget.editing).notifier);

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _nameController.text = editing.name ?? '';
      _notesController.text = editing.notes ?? '';
    }
    _events = _controller.events.listen(_onEvent);
  }

  @override
  void dispose() {
    _events?.cancel();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onEvent(CreateFastlaneVisitEvent event) {
    if (!mounted) return;
    final l10n = context.l10n;
    switch (event) {
      case FastlaneUpdated():
        context.pop();
        showGatesToast(
          context,
          type: GatesToastType.success,
          title: l10n.visitsFastlaneUpdatedToast,
        );
      case FastlaneCreated(:final visit):
        // Land on the shared F02 screen (share / copy / edit / cancel) with
        // the visits list underneath, so its back arrow returns to the list.
        final router = GoRouter.of(context);
        router.go('/');
        router.push('/visits/${visit.id}?created=1', extra: visit);
      case FastlaneUpdateFailed(:final failure):
        showGatesToast(
          context,
          type: GatesToastType.error,
          title: l10n.visitsSaveError,
          message: withFailureDetail(l10n, failure, l10n.visitsTryAgain),
        );
      case FastlaneCreateFailed(:final failure):
        showGatesToast(
          context,
          type: GatesToastType.error,
          title: l10n.visitsFastlaneCreateError,
          message: withFailureDetail(l10n, failure, l10n.visitsTryAgain),
        );
    }
  }

  Future<void> _pickVisitDate() async {
    // Must be UTC-normalized: TableCalendar normalizes firstDay/lastDay via
    // `DateTime.utc(y, m, d)` internally, so a local-time "today" here would
    // sit hours ahead of UTC midnight in negative UTC-offset timezones and
    // make today read as before firstDay (disabled).
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final picked = await showGatesDatePicker(
      context,
      initialDate: ref
          .read(createFastlaneVisitControllerProvider(widget.editing))
          .visitDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      title: context.l10n.visitsFastlaneVisitDate,
    );
    if (picked != null) _controller.setVisitDate(picked);
  }

  Future<void> _pickArrivalTime() async {
    final picked = await showGatesTimePicker(
      context,
      initialTime: ref
          .read(createFastlaneVisitControllerProvider(widget.editing))
          .arrivalTime,
    );
    if (picked != null) _controller.setArrivalTime(picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _controller.submit(
      name: _nameController.text,
      notes: _notesController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      createFastlaneVisitControllerProvider(widget.editing),
    );
    final membership = ref.watch(selectedMembershipProvider).value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          _isEditing
              ? context.l10n.visitsPendingEdit
              : context.l10n.visitsFastlaneTitle,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(GatesSpacing.space24),
            children: [
              if (membership != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.visitsUnitUpper,
                      style: context.gatesText.caption,
                    ),
                    const SizedBox(height: GatesSpacing.space4),
                    Text(
                      membership.label,
                      style: GatesTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GatesSpacing.space16),
              ],
              GatesTextField(
                controller: _nameController,
                label: context.l10n.visitsFastlaneNameLabel,
                hintText: context.l10n.visitsFastlaneNameHint,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.l10n.visitsFastlaneNameRequired
                    : null,
              ),
              const SizedBox(height: GatesSpacing.space16),
              GatesTapField(
                label: context.l10n.visitsFastlaneVisitDate,
                value: formatVisitDate(context.l10n, state.visitDate),
                helper: context.l10n.visitsFastlaneDateHelper,
                icon: Icons.calendar_month_outlined,
                onTap: _pickVisitDate,
              ),
              const SizedBox(height: GatesSpacing.space16),
              GatesTapField(
                label: context.l10n.visitsFastlaneArrivalLabel,
                value: formatClockText(state.arrivalTime),
                onTap: _pickArrivalTime,
              ),
              const SizedBox(height: GatesSpacing.space16),
              GatesTextArea(
                controller: _notesController,
                maxLength: _notesMaxLength,
              ),
              const SizedBox(height: GatesSpacing.space8),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(GatesSpacing.space24),
        child: GatesButton(
          label: _isEditing
              ? context.l10n.visitsSaveChanges
              : context.l10n.visitsFastlaneCreate,
          loading: state.isSubmitting,
          onPressed: state.isSubmitting ? null : _submit,
        ),
      ),
    );
  }
}

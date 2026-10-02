import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_phone_field.dart';
import '../../../core/widgets/gates_select_field.dart';
import '../../../core/widgets/gates_switch_row.dart';
import '../../../core/widgets/gates_text_area.dart';
import '../../../core/widgets/gates_text_field.dart';
import '../../../core/widgets/gates_time_picker.dart';
import '../../../core/widgets/gates_upload_card.dart';
import '../../../l10n/l10n.dart';
import '../domain/visit.dart';
import 'create_frequent_visit_controller.dart';
import 'frequent_visit_formatters.dart';
import 'schedule_block_card.dart';

const frequentNotesMaxLength = 120;

/// Step 1 "Datos de la visita": name, type, phone, ID document, vehicle.
class FrequentDataStep extends StatelessWidget {
  const FrequentDataStep({
    super.key,
    required this.state,
    required this.controller,
    required this.nameController,
    required this.phoneController,
    required this.plateController,
    required this.onPickDocument,
  });

  final CreateFrequentVisitState state;
  final CreateFrequentVisitController controller;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController plateController;
  final VoidCallback onPickDocument;

  String? _documentLabel(BuildContext context) {
    final file = state.document;
    if (file == null) {
      return state.keepsExistingDocument
          ? context.l10n.visitsFrequentCurrentDocument
          : null;
    }
    final mb = state.documentSize / (1024 * 1024);
    return '${file.name} · ${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final documentError = state.documentError;
    final uploadState = state.isSubmitting
        ? GatesUploadState.uploading
        : documentError != null || state.documentMissing
        ? GatesUploadState.error
        : state.hasDocument
        ? GatesUploadState.ready
        : GatesUploadState.empty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GatesTextField(
          controller: nameController,
          label: l10n.visitsFrequentNameLabel,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? l10n.visitsFrequentNameRequired
              : null,
        ),
        const SizedBox(height: GatesSpacing.space16),
        GatesSelectField<VisitorRole>(
          label: l10n.visitsFrequentTypeLabel,
          value: state.role,
          options: {
            for (final r in VisitorRole.values) r: visitorRoleLabel(l10n, r),
          },
          onChanged: controller.setRole,
        ),
        const SizedBox(height: GatesSpacing.space16),
        GatesPhoneField(
          controller: phoneController,
          country: state.country,
          onCountryChanged: controller.setCountry,
          validator: (v) {
            final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
            if (digits.isEmpty) return null;
            return digits.length < 7 || digits.length > 12
                ? l10n.visitsFrequentPhoneInvalid
                : null;
          },
        ),
        const SizedBox(height: GatesSpacing.space16),
        GatesUploadCard(
          title: l10n.visitsFrequentIdDocumentRequired,
          emptyDescription: l10n.visitsFrequentIdDocumentHint,
          state: uploadState,
          fileLabel: _documentLabel(context),
          errorDescription: documentError == null
              ? l10n.visitsFrequentIdDocumentMissing
              : l10n.visitsFrequentPhotoTooBig,
          onPick: onPickDocument,
          onRemove: controller.removeDocument,
        ),
        const SizedBox(height: GatesSpacing.space16),
        GatesSwitchRow(
          label: l10n.visitsFrequentHasVehicle,
          description: l10n.visitsFrequentHasVehicleHint,
          value: state.hasVehicle,
          onChanged: controller.setHasVehicle,
        ),
        const SizedBox(height: GatesSpacing.space16),
        GatesTextField(
          controller: plateController,
          label: l10n.visitsFrequentPlateLabel,
          hintText: l10n.visitsFrequentPlateHint,
          enabled: state.hasVehicle,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          validator: (v) => state.hasVehicle && (v == null || v.trim().isEmpty)
              ? l10n.visitsFrequentPlateRequired
              : null,
        ),
      ],
    );
  }
}

/// Step 2 "Días y horario": frequency, schedule or custom blocks, notes and
/// the arrival alert.
class FrequentScheduleStep extends StatelessWidget {
  const FrequentScheduleStep({
    super.key,
    required this.state,
    required this.controller,
    required this.notesController,
  });

  final CreateFrequentVisitState state;
  final CreateFrequentVisitController controller;
  final TextEditingController notesController;

  Future<void> _pickScheduleTime(
    BuildContext context, {
    required bool isStart,
  }) async {
    final picked = await showGatesTimePicker(
      context,
      initialTime: isStart ? state.scheduleStart : state.scheduleEnd,
    );
    if (picked == null) return;
    if (isStart) {
      controller.setScheduleStart(picked);
    } else {
      controller.setScheduleEnd(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isCustom = state.recurrence == Recurrence.custom;
    final blocks = state.blocks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GatesSelectField<Recurrence>(
          label: l10n.visitsFrequentFrequencyLabel,
          value: state.recurrence,
          options: {
            for (final r in Recurrence.values) r: recurrenceLabel(l10n, r),
          },
          onChanged: controller.setRecurrence,
        ),
        const SizedBox(height: GatesSpacing.space12),
        if (isCustom) ...[
          Text(
            l10n.visitsFrequentGroupDaysHint,
            style: context.gatesText.caption.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: GatesSpacing.space12),
          for (var i = 0; i < blocks.length; i++) ...[
            ScheduleBlockCard(
              index: i,
              block: blocks[i],
              takenDays: state.daysTakenByOthers(i),
              onToggleDay: (day) => controller.toggleBlockDay(i, day),
              onStartChanged: (t) => controller.setBlockStart(i, t),
              onEndChanged: (t) => controller.setBlockEnd(i, t),
              onRemove: blocks.length > 1
                  ? () => controller.removeBlock(i)
                  : null,
            ),
            const SizedBox(height: GatesSpacing.space12),
          ],
          _AddBlockButton(
            onPressed: state.allDaysTaken ? null : controller.addBlock,
          ),
        ] else ...[
          GatesSelectField<ScheduleType>(
            label: l10n.visitsFrequentScheduleLabel,
            value: state.scheduleType,
            options: {
              ScheduleType.allDay: l10n.visitsAllDay,
              ScheduleType.custom: l10n.visitsRecurrenceCustom,
            },
            onChanged: controller.setScheduleType,
          ),
          if (state.scheduleType == ScheduleType.custom) ...[
            const SizedBox(height: GatesSpacing.space12),
            Row(
              children: [
                Expanded(
                  child: GatesTimeField(
                    label: l10n.visitsScheduleFrom,
                    value: formatClockField(state.scheduleStart),
                    onTap: () => _pickScheduleTime(context, isStart: true),
                  ),
                ),
                const SizedBox(width: GatesSpacing.space8),
                Expanded(
                  child: GatesTimeField(
                    label: l10n.visitsScheduleTo,
                    value: formatClockField(state.scheduleEnd),
                    onTap: () => _pickScheduleTime(context, isStart: false),
                  ),
                ),
              ],
            ),
          ],
        ],
        const SizedBox(height: GatesSpacing.space16),
        GatesTextArea(
          controller: notesController,
          maxLength: frequentNotesMaxLength,
        ),
        const SizedBox(height: GatesSpacing.space16),
        GatesSwitchRow(
          label: l10n.visitsFrequentNotifyLabel,
          description: l10n.visitsFrequentNotifyHint,
          value: state.notifyOnArrival,
          onChanged: controller.setNotifyOnArrival,
        ),
      ],
    );
  }
}

/// Figma "Agregar bloque de horario": a white 48px pill.
class _AddBlockButton extends StatelessWidget {
  const _AddBlockButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: context.palette.bgSurface,
          foregroundColor: context.palette.textBrand,
          disabledForegroundColor: context.palette.textSecondary,
          shape: const StadiumBorder(),
          textStyle: GatesTypography.label,
        ),
        child: Text(context.l10n.visitsFrequentAddBlock),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_time_picker.dart';
import 'frequent_visit_formatters.dart';
import '../domain/visit.dart';

/// Mutable state of one "Bloque de horario" while the form is being filled.
class ScheduleBlockDraft {
  ScheduleBlockDraft({
    Set<String>? days,
    this.start = const TimeOfDay(hour: 8, minute: 0),
    this.end = const TimeOfDay(hour: 22, minute: 0),
  }) : days = days ?? {};

  final Set<String> days;
  TimeOfDay start;
  TimeOfDay end;

  ScheduleBlock toBlock() =>
      ScheduleBlock(days: {...days}, start: start, end: end);
}

const _dayInitials = {
  'mon': 'L',
  'tue': 'M',
  'wed': 'M',
  'thu': 'J',
  'fri': 'V',
  'sat': 'S',
  'sun': 'D',
};

/// Figma "Visitas / Bloque de horario" (node 384:842): weekday pills plus a
/// Desde / Hasta range. [takenDays] are days another block already covers —
/// they render disabled so a day belongs to one block only.
class ScheduleBlockCard extends StatelessWidget {
  const ScheduleBlockCard({
    super.key,
    required this.index,
    required this.draft,
    required this.takenDays,
    required this.onChanged,
    this.onRemove,
  });

  final int index;
  final ScheduleBlockDraft draft;
  final Set<String> takenDays;
  final VoidCallback onChanged;

  /// Null when this is the only block (it can't be removed).
  final VoidCallback? onRemove;

  Future<void> _pickTime(BuildContext context, {required bool isStart}) async {
    final picked = await showGatesTimePicker(
      context,
      initialTime: isStart ? draft.start : draft.end,
    );
    if (picked == null) return;
    if (isStart) {
      draft.start = picked;
    } else {
      draft.end = picked;
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GatesSpacing.space8),
      decoration: BoxDecoration(
        color: context.palette.bgCanvas,
        border: Border.all(color: context.palette.borderDefault),
        borderRadius: BorderRadius.circular(GatesRadius.radius16),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 32,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Bloque de horario ${index + 1}',
                    style: context.gatesText.caption,
                  ),
                ),
                if (onRemove != null)
                  InkWell(
                    onTap: onRemove,
                    child: SizedBox(
                      width: 44,
                      height: 32,
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: context.palette.textSecondary,
                        semanticLabel: 'Eliminar bloque',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: GatesSpacing.space8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in weekdayKeys)
                _DayPill(
                  label: _dayInitials[day]!,
                  semanticLabel: weekdayShortLabels[day]!,
                  selected: draft.days.contains(day),
                  enabled: !takenDays.contains(day),
                  onTap: () {
                    if (!draft.days.remove(day)) draft.days.add(day);
                    onChanged();
                  },
                ),
            ],
          ),
          const SizedBox(height: GatesSpacing.space8),
          Row(
            children: [
              Expanded(
                child: _TimeField(
                  label: 'Desde',
                  value: formatClockField(draft.start),
                  onTap: () => _pickTime(context, isStart: true),
                ),
              ),
              const SizedBox(width: GatesSpacing.space8),
              Expanded(
                child: _TimeField(
                  label: 'Hasta',
                  value: formatClockField(draft.end),
                  onTap: () => _pickTime(context, isStart: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      selected: selected,
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Material(
          color: selected ? context.palette.bgBrand : context.palette.bgSurface,
          shape: CircleBorder(
            side: BorderSide(
              color: selected
                  ? context.palette.borderSelectedBrand
                  : context.palette.borderDefault,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? onTap : null,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Text(
                  label,
                  style: GatesTypography.body.copyWith(
                    color: selected
                        ? context.palette.textOnBrand
                        : context.palette.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma "IFTA time field": label + time, with a clock glyph on the right.
class GatesTimeField extends StatelessWidget {
  const GatesTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      _TimeField(label: label, value: value, onTap: onTap);
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GatesRadius.radius16),
        side: BorderSide(color: context.palette.borderDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(GatesSpacing.space12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: context.gatesText.caption),
                    const SizedBox(height: GatesSpacing.space4),
                    Text(
                      value,
                      style: GatesTypography.body.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
              Icon(Icons.schedule, size: 20, color: context.palette.textBrand),
            ],
          ),
        ),
      ),
    );
  }
}

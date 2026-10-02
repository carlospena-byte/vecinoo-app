import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_time_picker.dart';
import '../../../l10n/l10n.dart';
import 'frequent_visit_formatters.dart';
import '../domain/visit.dart';

String _dayInitial(AppLocalizations l10n, String day) => switch (day) {
  'mon' => l10n.visitsWeekdayInitialMon,
  'tue' => l10n.visitsWeekdayInitialTue,
  'wed' => l10n.visitsWeekdayInitialWed,
  'thu' => l10n.visitsWeekdayInitialThu,
  'fri' => l10n.visitsWeekdayInitialFri,
  'sat' => l10n.visitsWeekdayInitialSat,
  _ => l10n.visitsWeekdayInitialSun,
};

/// Figma "Visitas / Bloque de horario" (node 384:842): weekday pills plus a
/// Desde / Hasta range. [takenDays] are days another block already covers —
/// they render disabled so a day belongs to one block only.
class ScheduleBlockCard extends StatelessWidget {
  const ScheduleBlockCard({
    super.key,
    required this.index,
    required this.block,
    required this.takenDays,
    required this.onToggleDay,
    required this.onStartChanged,
    required this.onEndChanged,
    this.onRemove,
  });

  final int index;
  final ScheduleBlock block;
  final Set<String> takenDays;
  final ValueChanged<String> onToggleDay;
  final ValueChanged<TimeOfDay> onStartChanged;
  final ValueChanged<TimeOfDay> onEndChanged;

  /// Null when this is the only block (it can't be removed).
  final VoidCallback? onRemove;

  Future<void> _pickTime(BuildContext context, {required bool isStart}) async {
    final picked = await showGatesTimePicker(
      context,
      initialTime: isStart ? block.start : block.end,
    );
    if (picked == null) return;
    (isStart ? onStartChanged : onEndChanged)(picked);
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
                    context.l10n.visitsScheduleBlockTitle(index + 1),
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
                        TablerIcons.x,
                        size: 20,
                        color: context.palette.textSecondary,
                        semanticLabel: context.l10n.visitsScheduleBlockRemove,
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
                  label: _dayInitial(context.l10n, day),
                  semanticLabel: weekdayShortLabel(context.l10n, day),
                  selected: block.days.contains(day),
                  enabled: !takenDays.contains(day),
                  onTap: () => onToggleDay(day),
                ),
            ],
          ),
          const SizedBox(height: GatesSpacing.space8),
          Row(
            children: [
              Expanded(
                child: _TimeField(
                  label: context.l10n.visitsScheduleFrom,
                  value: formatClockField(block.start),
                  onTap: () => _pickTime(context, isStart: true),
                ),
              ),
              const SizedBox(width: GatesSpacing.space8),
              Expanded(
                child: _TimeField(
                  label: context.l10n.visitsScheduleTo,
                  value: formatClockField(block.end),
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
                      style: GatesTypography.label.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                TablerIcons.clock,
                size: 20,
                color: context.palette.textBrand,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

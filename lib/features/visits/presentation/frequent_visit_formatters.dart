import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/l10n.dart';
import '../domain/access_movement.dart';
import '../domain/visit.dart';

/// "08:00 AM" — how the Figma time fields show a time.
String formatClockField(TimeOfDay time) => DateFormat(
  'hh:mm a',
  'en_US',
).format(DateTime(2000, 1, 1, time.hour, time.minute));

/// "8:00 a. m." — the localized form used inside sentences.
String formatClockText(TimeOfDay time) => DateFormat(
  'h:mm a',
  'es',
).format(DateTime(2000, 1, 1, time.hour, time.minute));

String _daysLabel(AppLocalizations l10n, Iterable<String> days) => weekdayKeys
    .where(days.contains)
    .map((d) => weekdayShortLabel(l10n, d))
    .join(', ');

/// "Lunes a viernes · Todo el día" or, for custom blocks, one line per block:
/// "Lun, Mar, Mié · 8:00 a. m.–10:00 p. m.".
String frequentScheduleSummary(AppLocalizations l10n, Visit visit) {
  final blocks = visit.scheduleBlocks;
  if (visit.recurrence == Recurrence.custom &&
      blocks != null &&
      blocks.isNotEmpty) {
    return blocks
        .map(
          (b) =>
              '${_daysLabel(l10n, b.days)} · ${formatClockText(b.start)}–${formatClockText(b.end)}',
        )
        .join('\n');
  }
  final frequency = visit.recurrence == null
      ? l10n.visitsFrequentAccess
      : recurrenceLabel(l10n, visit.recurrence!);
  final start = visit.scheduleStart;
  final end = visit.scheduleEnd;
  final window =
      visit.scheduleType == ScheduleType.custom && start != null && end != null
      ? '${formatClockText(start)}–${formatClockText(end)}'
      : l10n.visitsAllDay;
  return '$frequency · $window';
}

String _movementDay(AppLocalizations l10n, DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) return l10n.visitsMovementDayToday;
  if (day == today.subtract(const Duration(days: 1))) {
    return l10n.visitsMovementDayYesterday;
  }
  final formatted =
      '${DateFormat('d MMM', 'es').format(date).replaceAll('.', '')}.';
  return l10n.visitsMovementDayDate(formatted.toLowerCase());
}

/// "Ingreso hoy, 8:05 a. m." / "Salida ayer, 6:30 p. m." — whichever of the
/// entry or exit happened last.
String lastMovementLabel(AppLocalizations l10n, AccessMovement movement) {
  final out = movement.checkedOutAt;
  final when = out ?? movement.checkedInAt;
  final day = _movementDay(l10n, when);
  final time = DateFormat('h:mm a', 'es').format(when);
  return out == null
      ? l10n.visitsLastEntry(day, time)
      : l10n.visitsLastExit(day, time);
}

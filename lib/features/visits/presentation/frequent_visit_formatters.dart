import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/visits_repository.dart';
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

String _daysLabel(Iterable<String> days) => weekdayKeys
    .where(days.contains)
    .map((d) => weekdayShortLabels[d])
    .join(', ');

/// "Lunes a viernes · Todo el día" or, for custom blocks, one line per block:
/// "Lun, Mar, Mié · 8:00 a. m.–10:00 p. m.".
String frequentScheduleSummary(Visit visit) {
  final blocks = visit.scheduleBlocks;
  if (visit.recurrence == Recurrence.custom &&
      blocks != null &&
      blocks.isNotEmpty) {
    return blocks
        .map(
          (b) =>
              '${_daysLabel(b.days)} · ${formatClockText(b.start)}–${formatClockText(b.end)}',
        )
        .join('\n');
  }
  final frequency = visit.recurrence == null
      ? 'Acceso frecuente'
      : recurrenceLabel(visit.recurrence!);
  final start = visit.scheduleStart;
  final end = visit.scheduleEnd;
  final window =
      visit.scheduleType == ScheduleType.custom && start != null && end != null
      ? '${formatClockText(start)}–${formatClockText(end)}'
      : 'Todo el día';
  return '$frequency · $window';
}

String _dayPrefix(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) return 'Hoy';
  if (day == today.subtract(const Duration(days: 1))) return 'Ayer';
  return '${DateFormat('d MMM', 'es').format(date).replaceAll('.', '')}.';
}

/// "Ingreso hoy, 8:05 a. m." / "Salida ayer, 6:30 p. m." — whichever of the
/// entry or exit happened last.
String lastMovementLabel(AccessMovement movement) {
  final out = movement.checkedOutAt;
  final when = out ?? movement.checkedInAt;
  final prefix = _dayPrefix(when).toLowerCase();
  final time = DateFormat('h:mm a', 'es').format(when);
  return '${out == null ? 'Ingreso' : 'Salida'} ${prefix == 'hoy' || prefix == 'ayer' ? prefix : 'el $prefix'}, $time';
}

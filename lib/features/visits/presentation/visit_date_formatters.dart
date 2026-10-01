import 'package:intl/intl.dart';

import '../../../l10n/l10n.dart';

/// "Hoy, 30 sept 2026" / "Mañana, 1 oct 2026" / "5 oct 2026" — one place for
/// how a visit date reads across the visit screens.
String formatVisitDate(AppLocalizations l10n, DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final formatted = DateFormat('d MMM y', 'es').format(date);
  if (day == today) return l10n.visitsDateToday(formatted);
  if (day == today.add(const Duration(days: 1))) {
    return l10n.visitsDateTomorrow(formatted);
  }
  return formatted;
}

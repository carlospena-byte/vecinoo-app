import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../l10n/l10n.dart';
import '../domain/amenity.dart';
import '../domain/amenity_blackout.dart';
import '../domain/amenity_booking_limit.dart';

/// Localized labels for amenity domain values. Kept in the presentation layer
/// so the domain stays free of UI copy.

/// e.g. "1 hora", "2 horas", "90 minutos".
String amenityDurationLabel(AppLocalizations l10n, int minutes) {
  if (minutes % 60 == 0) return l10n.amenitiesDurationHours(minutes ~/ 60);
  return l10n.amenitiesDurationMinutes(minutes);
}

/// e.g. "Lun, Mar, Mié, Jue 8:00-9:00".
String amenityScheduleBlockLabel(
  AppLocalizations l10n,
  AmenityScheduleBlock block,
) {
  final days = block.days.map((d) => _dayLabel(l10n, d)).join(', ');
  return '$days ${block.openLabel}-${block.closeLabel}';
}

String _dayLabel(AppLocalizations l10n, String day) => switch (day) {
  'mon' => l10n.amenitiesDayMon,
  'tue' => l10n.amenitiesDayTue,
  'wed' => l10n.amenitiesDayWed,
  'thu' => l10n.amenitiesDayThu,
  'fri' => l10n.amenitiesDayFri,
  'sat' => l10n.amenitiesDaySat,
  'sun' => l10n.amenitiesDaySun,
  _ => day,
};

/// Label for a `paymentMethods` entry, matching gates-admin's copy for
/// `{cash, card, transfer}`.
String amenityPaymentMethodLabel(AppLocalizations l10n, String value) =>
    switch (value) {
      'cash' => l10n.amenitiesPaymentCash,
      'card' => l10n.amenitiesPaymentCard,
      'transfer' => l10n.amenitiesPaymentTransfer,
      _ => value,
    };

/// e.g. "Máximo 2 reservas por semana".
String amenityBookingLimitLabel(
  AppLocalizations l10n,
  AmenityBookingLimit limit,
) {
  final period = switch (limit.period) {
    BookingLimitPeriod.day => l10n.amenitiesPeriodDay,
    BookingLimitPeriod.week => l10n.amenitiesPeriodWeek,
    BookingLimitPeriod.month => l10n.amenitiesPeriodMonth,
  };
  return l10n.amenitiesBookingLimit(limit.maxCount, period);
}

String _blackoutRange(AmenityBlackout blackout) {
  final formatter = DateFormat('d MMM', 'es');
  return isSameDay(blackout.startDate, blackout.endDate)
      ? formatter.format(blackout.startDate)
      : '${formatter.format(blackout.startDate)} – ${formatter.format(blackout.endDate)}';
}

bool _hasReason(AmenityBlackout blackout) =>
    blackout.reason != null && blackout.reason!.isNotEmpty;

/// Detail-screen form: "12 oct – 14 oct · Mantenimiento".
String amenityBlackoutLabel(AppLocalizations l10n, AmenityBlackout blackout) {
  final range = _blackoutRange(blackout);
  return _hasReason(blackout)
      ? l10n.amenitiesBlackoutWithReason(range, blackout.reason!)
      : range;
}

/// Date-sheet form. [withPrefix] matches the design's copy, which only
/// spells out "Cerrado" once for the group rather than repeating it before
/// every date range.
String amenityBlackoutSheetLabel(
  AppLocalizations l10n,
  AmenityBlackout blackout, {
  bool withPrefix = true,
}) {
  final range = _blackoutRange(blackout);
  if (_hasReason(blackout)) {
    return withPrefix
        ? l10n.amenitiesBlackoutClosedWithReason(range, blackout.reason!)
        : l10n.amenitiesBlackoutRangeWithReason(range, blackout.reason!);
  }
  return withPrefix ? l10n.amenitiesBlackoutClosed(range) : range;
}

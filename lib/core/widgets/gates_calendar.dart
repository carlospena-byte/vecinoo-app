import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../theme/app_theme.dart';
import 'gates_button.dart';
import '../../l10n/l10n.dart';

/// "Octubre 2026" — capitalized month name plus year, no "de" in between
/// (unlike `DateFormat.yMMMM('es')`, which reads "octubre de 2026").
String _monthTitle(DateTime date) {
  final month = DateFormat('MMMM', 'es').format(date);
  return '${month[0].toUpperCase()}${month.substring(1)} ${date.year}';
}

/// The month-grid calendar card shared by every date picker in the app
/// (originally built for [BookingDateTimeSheet]) — a bordered/rounded
/// [TableCalendar] styled to match the Gates design tokens instead of
/// `table_calendar`'s defaults.
class GatesCalendar extends StatelessWidget {
  const GatesCalendar({
    super.key,
    required this.focusedDay,
    required this.firstDay,
    required this.lastDay,
    this.selectedDay,
    this.onDaySelected,
    this.rangeStart,
    this.rangeEnd,
    this.onRangeSelected,
    this.enabledDayPredicate,
  }) : assert(
         onRangeSelected != null ||
             (selectedDay != null && onDaySelected != null),
         'Pass selectedDay + onDaySelected, or onRangeSelected',
       );

  final DateTime? selectedDay;
  final DateTime focusedDay;
  final void Function(DateTime selected, DateTime focused)? onDaySelected;

  /// Range mode: set when the calendar picks a span of days instead of one.
  /// [onRangeSelected] gets the start (and the end once the second tap lands).
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final void Function(DateTime start, DateTime? end, DateTime focused)?
  onRangeSelected;
  final DateTime firstDay;
  final DateTime lastDay;
  final bool Function(DateTime day)? enabledDayPredicate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GatesSpacing.space16),
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        borderRadius: BorderRadius.circular(GatesRadius.radius24),
      ),
      child: TableCalendar(
        startingDayOfWeek: StartingDayOfWeek.monday,
        firstDay: firstDay,
        lastDay: lastDay,
        focusedDay: focusedDay,
        locale: 'es',
        daysOfWeekHeight: 24,
        rowHeight: 44,
        selectedDayPredicate: (day) => isSameDay(day, selectedDay),
        onDaySelected: onDaySelected,
        rangeSelectionMode: onRangeSelected == null
            ? RangeSelectionMode.disabled
            : RangeSelectionMode.toggledOn,
        rangeStartDay: rangeStart,
        rangeEndDay: rangeEnd,
        onRangeSelected: onRangeSelected == null
            ? null
            : (start, end, focused) {
                if (start != null) onRangeSelected!(start, end, focused);
              },
        // `day` here is always UTC-normalized by TableCalendar (it calls
        // `DateTime.utc(y, m, d)` internally), so the default predicate must
        // compare against a UTC-normalized "today" too — otherwise a local
        // DateTime "today" sits hours ahead of UTC midnight in any negative
        // UTC-offset timezone and today reads as disabled.
        enabledDayPredicate:
            enabledDayPredicate ??
            (day) {
              final now = DateTime.now();
              return !day.isBefore(DateTime.utc(now.year, now.month, now.day));
            },
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: {
          CalendarFormat.month: context.l10n.commonMonth,
        },
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: GatesTypography.label,
          titleTextFormatter: (date, locale) => _monthTitle(date),
          leftChevronIcon: Icon(
            TablerIcons.chevronLeft,
            size: 20,
            color: context.palette.textPrimary,
          ),
          rightChevronIcon: Icon(
            TablerIcons.chevronRight,
            size: 20,
            color: context.palette.textPrimary,
          ),
          headerPadding: EdgeInsets.zero,
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: context.gatesText.caption,
          weekendStyle: context.gatesText.caption,
        ),
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) {
            const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
            return Center(
              child: Text(
                labels[day.weekday - 1],
                style: context.gatesText.caption,
              ),
            );
          },
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: true,
          cellMargin: EdgeInsets.zero,
          defaultTextStyle: GatesTypography.body,
          weekendTextStyle: GatesTypography.body,
          outsideTextStyle: GatesTypography.body,
          disabledTextStyle: GatesTypography.body.copyWith(
            color: context.palette.textSecondary,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              BorderSide(color: context.palette.bgBrand),
            ),
          ),
          todayTextStyle: GatesTypography.body,
          selectedDecoration: BoxDecoration(
            color: context.palette.bgBrand,
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              BorderSide(color: context.palette.borderSelectedBrand, width: 2),
            ),
          ),
          selectedTextStyle: GatesTypography.body.copyWith(
            color: context.palette.textOnBrand,
          ),
          rangeStartDecoration: BoxDecoration(
            color: context.palette.bgBrand,
            shape: BoxShape.circle,
          ),
          rangeEndDecoration: BoxDecoration(
            color: context.palette.bgBrand,
            shape: BoxShape.circle,
          ),
          rangeStartTextStyle: GatesTypography.body.copyWith(
            color: context.palette.textOnBrand,
          ),
          rangeEndTextStyle: GatesTypography.body.copyWith(
            color: context.palette.textOnBrand,
          ),
          rangeHighlightColor: context.palette.bgAccent,
          withinRangeTextStyle: GatesTypography.body,
          withinRangeDecoration: const BoxDecoration(),
        ),
      ),
    );
  }
}

/// Standalone date-only bottom sheet built on [GatesCalendar] — for any
/// screen that just needs a single day (no time range), e.g. FastLane's
/// "Fecha de visita". Reuses the same calendar card as
/// [BookingDateTimeSheet] instead of the platform's `showDatePicker`.
Future<DateTime?> showGatesDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? title,
  String? primaryLabel,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(GatesRadius.radius24),
      ),
    ),
    builder: (context) => _GatesDatePickerSheet(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      title: title ?? context.l10n.commonDate,
      primaryLabel: primaryLabel ?? context.l10n.commonContinue,
    ),
  );
}

class _GatesDatePickerSheet extends StatefulWidget {
  const _GatesDatePickerSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.title,
    required this.primaryLabel,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;
  final String primaryLabel;

  @override
  State<_GatesDatePickerSheet> createState() => _GatesDatePickerSheetState();
}

class _GatesDatePickerSheetState extends State<_GatesDatePickerSheet> {
  late DateTime _selectedDay = widget.initialDate;
  late DateTime _focusedDay = widget.initialDate;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            GatesSpacing.space24,
            GatesSpacing.space24,
            GatesSpacing.space24,
            GatesSpacing.space16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.title, style: GatesTypography.headingMedium),
                  IconButton(
                    tooltip: context.l10n.commonClose,
                    icon: const Icon(TablerIcons.x),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: GatesSpacing.space16),
              GatesCalendar(
                selectedDay: _selectedDay,
                focusedDay: _focusedDay,
                firstDay: widget.firstDate,
                lastDay: widget.lastDate,
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
              ),
              const SizedBox(height: GatesSpacing.space24),
              SizedBox(
                width: double.infinity,
                child: GatesButton(
                  label: widget.primaryLabel,
                  onPressed: () => Navigator.of(context).pop(_selectedDay),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet to pick a span of days on [GatesCalendar] — e.g. to filter
/// the payment history. A single tap picks one day; a second tap closes the
/// range. Resolves to null when dismissed.
Future<({DateTime start, DateTime end})?> showGatesDateRangePicker(
  BuildContext context, {
  required ({DateTime start, DateTime end}) initialRange,
  required DateTime firstDate,
  required DateTime lastDate,
  String? title,
  String? primaryLabel,
}) {
  return showModalBottomSheet<({DateTime start, DateTime end})>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(GatesRadius.radius24),
      ),
    ),
    builder: (context) => _GatesDateRangePickerSheet(
      initialRange: initialRange,
      firstDate: firstDate,
      lastDate: lastDate,
      title: title ?? context.l10n.commonDateRange,
      primaryLabel: primaryLabel ?? context.l10n.commonApply,
    ),
  );
}

class _GatesDateRangePickerSheet extends StatefulWidget {
  const _GatesDateRangePickerSheet({
    required this.initialRange,
    required this.firstDate,
    required this.lastDate,
    required this.title,
    required this.primaryLabel,
  });

  final ({DateTime start, DateTime end}) initialRange;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;
  final String primaryLabel;

  @override
  State<_GatesDateRangePickerSheet> createState() =>
      _GatesDateRangePickerSheetState();
}

class _GatesDateRangePickerSheetState
    extends State<_GatesDateRangePickerSheet> {
  late DateTime _start = widget.initialRange.start;
  late DateTime? _end = widget.initialRange.end;
  late DateTime _focusedDay = widget.initialRange.start;

  /// TableCalendar hands back UTC days; the app works in local calendar days.
  static DateTime _local(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          GatesSpacing.space24,
          GatesSpacing.space24,
          GatesSpacing.space24,
          GatesSpacing.space16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: GatesTypography.headingMedium,
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.commonClose,
                  icon: const Icon(TablerIcons.x),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: GatesSpacing.space16),
            GatesCalendar(
              focusedDay: _focusedDay,
              firstDay: widget.firstDate,
              lastDay: widget.lastDate,
              rangeStart: _start,
              rangeEnd: _end,
              enabledDayPredicate: (_) => true,
              onRangeSelected: (start, end, focused) {
                setState(() {
                  _start = _local(start);
                  _end = end == null ? null : _local(end);
                  _focusedDay = focused;
                });
              },
            ),
            const SizedBox(height: GatesSpacing.space24),
            SizedBox(
              width: double.infinity,
              child: GatesButton(
                label: widget.primaryLabel,
                // One tap = that single day.
                onPressed: () =>
                    Navigator.of(context)
                        .pop((start: _start, end: _end ?? _start)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

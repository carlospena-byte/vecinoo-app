import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../theme/app_theme.dart';
import 'gates_button.dart';

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
    required this.selectedDay,
    required this.focusedDay,
    required this.onDaySelected,
    required this.firstDay,
    required this.lastDay,
    this.enabledDayPredicate,
  });

  final DateTime selectedDay;
  final DateTime focusedDay;
  final void Function(DateTime selected, DateTime focused) onDaySelected;
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
        availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: GatesTypography.label,
          titleTextFormatter: (date, locale) => _monthTitle(date),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            size: 20,
            color: context.palette.textPrimary,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
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
  String title = 'Fecha',
  String primaryLabel = 'Continuar',
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
      title: title,
      primaryLabel: primaryLabel,
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
                    icon: const Icon(Icons.close),
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

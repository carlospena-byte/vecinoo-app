import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_calendar.dart';
import '../../../core/widgets/gates_time_picker.dart';
import '../domain/amenity.dart';
import '../domain/amenity_blackout.dart';

/// A day + time range picked in [BookingDateTimeSheet]. For a fixed-duration
/// amenity, [end] is always [start] + `bookingDurationMinutes`.
class BookingSelection {
  const BookingSelection({
    required this.day,
    required this.start,
    required this.end,
  });

  final DateTime day;
  final TimeOfDay start;
  final TimeOfDay end;

  DateTime get startDateTime =>
      DateTime(day.year, day.month, day.day, start.hour, start.minute);
  DateTime get endDateTime =>
      DateTime(day.year, day.month, day.day, end.hour, end.minute);
}

/// [withPrefix] matches the design's copy, which only spells out "Cerrado"
/// once for the group rather than repeating it before every date range.
String _blackoutLabel(AmenityBlackout blackout, {bool withPrefix = true}) {
  final formatter = DateFormat('d MMM', 'es');
  final range = isSameDay(blackout.startDate, blackout.endDate)
      ? formatter.format(blackout.startDate)
      : '${formatter.format(blackout.startDate)} – ${formatter.format(blackout.endDate)}';
  final prefix = withPrefix ? 'Cerrado ' : '';
  return blackout.reason == null || blackout.reason!.isEmpty
      ? '$prefix$range'
      : '$prefix$range: ${blackout.reason}';
}

String _time(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String _durationLabel(int minutes) {
  if (minutes % 60 == 0) {
    final hours = minutes ~/ 60;
    return hours == 1 ? '1 hora' : '$hours horas';
  }
  return '$minutes minutos';
}

/// Bottom sheet for picking a booking's day and time — Figma "B01 · Elegir
/// fecha y horario" / "B03 · Cambiar fecha y horario" (node 265:1504 /
/// 265:1721). Fixed-duration amenities only ask for a start time and
/// compute the end; flexible ones (no `bookingDurationMinutes`) ask for
/// both.
Future<BookingSelection?> showBookingDateTimeSheet(
  BuildContext context, {
  required Amenity amenity,
  required List<AmenityBlackout> blackouts,
  BookingSelection? initial,
  String primaryLabel = 'Continuar',
}) {
  return showModalBottomSheet<BookingSelection>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(GatesRadius.radius24),
      ),
    ),
    builder: (context) => BookingDateTimeSheet(
      amenity: amenity,
      blackouts: blackouts,
      initial: initial,
      primaryLabel: primaryLabel,
    ),
  );
}

class BookingDateTimeSheet extends StatefulWidget {
  const BookingDateTimeSheet({
    super.key,
    required this.amenity,
    required this.blackouts,
    this.initial,
    this.primaryLabel = 'Continuar',
  });

  final Amenity amenity;
  final List<AmenityBlackout> blackouts;
  final BookingSelection? initial;
  final String primaryLabel;

  @override
  State<BookingDateTimeSheet> createState() => _BookingDateTimeSheetState();
}

class _BookingDateTimeSheetState extends State<BookingDateTimeSheet> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  late TimeOfDay _startTime;
  TimeOfDay? _endTime;
  String? _error;

  bool get _isFixedDuration => widget.amenity.bookingDurationMinutes != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _selectedDay = initial?.day ?? DateTime.now();
    _focusedDay = _selectedDay;
    _startTime = initial?.start ?? const TimeOfDay(hour: 9, minute: 0);
    _endTime = _isFixedDuration
        ? null
        : (initial?.end ?? const TimeOfDay(hour: 10, minute: 0));
  }

  TimeOfDay get _computedEndTime {
    if (!_isFixedDuration) return _endTime!;
    final minutes = widget.amenity.bookingDurationMinutes!;
    final totalMinutes = _startTime.hour * 60 + _startTime.minute + minutes;
    return TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );
  }

  bool _isBlackedOut(DateTime day) =>
      widget.blackouts.any((b) => b.covers(day));

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime ?? _startTime;
    final picked = await showGatesTimePicker(context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      _error = null;
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  void _submit() {
    if (!_isFixedDuration) {
      final start = DateTime(2000, 1, 1, _startTime.hour, _startTime.minute);
      final end = DateTime(2000, 1, 1, _endTime!.hour, _endTime!.minute);
      if (!end.isAfter(start)) {
        setState(
          () =>
              _error = 'La hora de fin debe ser después de la hora de inicio.',
        );
        return;
      }
    }
    Navigator.of(context).pop(
      BookingSelection(
        day: _selectedDay,
        start: _startTime,
        end: _computedEndTime,
      ),
    );
  }

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
                  Text('Fecha y horario', style: GatesTypography.headingMedium),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              if (widget.blackouts.isNotEmpty) ...[
                const SizedBox(height: GatesSpacing.space16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.palette.statusWarningBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < widget.blackouts.length; i++)
                        Text(
                          _blackoutLabel(
                            widget.blackouts[i],
                            withPrefix: i == 0,
                          ),
                          style: context.gatesText.caption.copyWith(
                            color: context.palette.statusWarning,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: GatesSpacing.space16),
              GatesCalendar(
                selectedDay: _selectedDay,
                focusedDay: _focusedDay,
                firstDay: DateTime.now().subtract(const Duration(days: 1)),
                lastDay: DateTime.now().add(const Duration(days: 180)),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                enabledDayPredicate: (day) =>
                    !day.isBefore(
                      DateTime.now().subtract(const Duration(days: 1)),
                    ) &&
                    !_isBlackedOut(day),
              ),
              const SizedBox(height: GatesSpacing.space16),
              if (_isFixedDuration)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _TimeField(
                        label: 'Inicio',
                        value: _time(_startTime),
                        onTap: () => _pickTime(isStart: true),
                      ),
                    ),
                    const SizedBox(width: GatesSpacing.space12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: GatesSpacing.space8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Termina a las',
                              style: context.gatesText.caption,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_time(_computedEndTime)} · '
                              '${_durationLabel(widget.amenity.bookingDurationMinutes!)}',
                              style: GatesTypography.body,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _TimeField(
                        label: 'Inicio',
                        value: _time(_startTime),
                        onTap: () => _pickTime(isStart: true),
                      ),
                    ),
                    const SizedBox(width: GatesSpacing.space12),
                    Expanded(
                      child: _TimeField(
                        label: 'Fin',
                        value: _time(_endTime!),
                        onTap: () => _pickTime(isStart: false),
                      ),
                    ),
                  ],
                ),
              if (_isFixedDuration) ...[
                const SizedBox(height: GatesSpacing.space8),
                Text(
                  'Cada reserva dura ${_durationLabel(widget.amenity.bookingDurationMinutes!)}.',
                  style: context.gatesText.caption,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: GatesSpacing.space8),
                Text(
                  _error!,
                  style: context.gatesText.caption.copyWith(
                    color: context.palette.statusError,
                  ),
                ),
              ],
              const SizedBox(height: GatesSpacing.space24),
              SizedBox(
                width: double.infinity,
                child: GatesButton(
                  label: widget.primaryLabel,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Time picker / IFTA" field — Figma node 33:157: a bordered 64px-tall card
/// with a small label above the value and a clock glyph on the trailing
/// edge, tapping into the platform's native time picker.
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: GatesSpacing.space12),
        decoration: BoxDecoration(
          color: context.palette.bgSurface,
          border: Border.all(color: context.palette.borderDefault),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.gatesText.caption),
                  const SizedBox(height: 4),
                  Text(value, style: GatesTypography.body),
                ],
              ),
            ),
            Icon(Icons.access_time, color: context.palette.textBrand, size: 20),
          ],
        ),
      ),
    );
  }
}

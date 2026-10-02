import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_calendar.dart';
import '../../../core/widgets/gates_time_picker.dart';
import '../../../l10n/l10n.dart';
import '../domain/amenity.dart';
import '../domain/amenity_blackout.dart';
import 'amenity_formatters.dart';
import 'booking_date_time_controller.dart';
import 'booking_selection.dart';

export 'booking_selection.dart';

String _time(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

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
  String? primaryLabel,
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

class BookingDateTimeSheet extends ConsumerStatefulWidget {
  const BookingDateTimeSheet({
    super.key,
    required this.amenity,
    required this.blackouts,
    this.initial,
    this.primaryLabel,
  });

  final Amenity amenity;
  final List<AmenityBlackout> blackouts;
  final BookingSelection? initial;

  /// Defaults to the localized "Continuar".
  final String? primaryLabel;

  @override
  ConsumerState<BookingDateTimeSheet> createState() =>
      _BookingDateTimeSheetState();
}

class _BookingDateTimeSheetState extends ConsumerState<BookingDateTimeSheet> {
  StreamSubscription<BookingSelectionConfirmed>? _events;

  BookingDateTimeArgs get _args => BookingDateTimeArgs(
    amenity: widget.amenity,
    blackouts: widget.blackouts,
    initial: widget.initial,
  );

  BookingDateTimeController get _controller =>
      ref.read(bookingDateTimeControllerProvider(_args).notifier);

  bool get _isFixedDuration => widget.amenity.bookingDurationMinutes != null;

  @override
  void initState() {
    super.initState();
    _events = _controller.events.listen((event) {
      if (mounted) Navigator.of(context).pop(event.selection);
    });
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final state = ref.read(bookingDateTimeControllerProvider(_args));
    final initial = isStart ? state.start : state.end ?? state.start;
    final picked = await showGatesTimePicker(context, initialTime: initial);
    if (picked == null || !mounted) return;
    if (isStart) {
      _controller.setStart(picked);
    } else {
      _controller.setEnd(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;
    final state = ref.watch(bookingDateTimeControllerProvider(args));
    final controller = _controller;
    final error = state.error;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  Text(
                    context.l10n.amenitiesDateTimeTitle,
                    style: GatesTypography.headingMedium,
                  ),
                  IconButton(
                    tooltip: context.l10n.amenitiesClose,
                    icon: const Icon(TablerIcons.x),
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
                          amenityBlackoutSheetLabel(
                            context.l10n,
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
                selectedDay: state.selectedDay,
                focusedDay: state.focusedDay,
                firstDay: DateTime.now().subtract(const Duration(days: 1)),
                lastDay: DateTime.now().add(const Duration(days: 180)),
                onDaySelected: controller.selectDay,
                enabledDayPredicate: controller.isDayEnabled,
              ),
              const SizedBox(height: GatesSpacing.space16),
              if (_isFixedDuration)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _TimeField(
                        label: context.l10n.amenitiesStart,
                        value: _time(state.start),
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
                              context.l10n.amenitiesEndsAt,
                              style: context.gatesText.caption,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_time(controller.computedEnd)} · '
                              '${amenityDurationLabel(context.l10n, widget.amenity.bookingDurationMinutes!)}',
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
                        label: context.l10n.amenitiesStart,
                        value: _time(state.start),
                        onTap: () => _pickTime(isStart: true),
                      ),
                    ),
                    const SizedBox(width: GatesSpacing.space12),
                    Expanded(
                      child: _TimeField(
                        label: context.l10n.amenitiesEnd,
                        value: _time(state.end!),
                        onTap: () => _pickTime(isStart: false),
                      ),
                    ),
                  ],
                ),
              if (_isFixedDuration) ...[
                const SizedBox(height: GatesSpacing.space8),
                Text(
                  context.l10n.amenitiesEachBookingLasts(
                    amenityDurationLabel(
                      context.l10n,
                      widget.amenity.bookingDurationMinutes!,
                    ),
                  ),
                  style: context.gatesText.caption,
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: GatesSpacing.space8),
                Text(
                  switch (error) {
                    BookingDateTimeError.endBeforeStart =>
                      context.l10n.amenitiesEndAfterStartError,
                  },
                  style: context.gatesText.caption.copyWith(
                    color: context.palette.statusError,
                  ),
                ),
              ],
              const SizedBox(height: GatesSpacing.space24),
              SizedBox(
                width: double.infinity,
                child: GatesButton(
                  label: widget.primaryLabel ?? context.l10n.amenitiesContinue,
                  onPressed: controller.submit,
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
            Icon(TablerIcons.clock, color: context.palette.textBrand, size: 20),
          ],
        ),
      ),
    );
  }
}

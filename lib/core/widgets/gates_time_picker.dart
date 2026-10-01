import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../l10n/l10n.dart';

/// A scrolling-wheel time picker (like an alarm-clock spinner) instead of
/// Material's analog clock dial, which residents found hard to use. Always
/// use this — never `showTimePicker` — for any time input in the app.
Future<TimeOfDay?> showGatesTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
}) {
  const minuteInterval = 5;
  final roundedMinute =
      (initialTime.minute / minuteInterval).round() * minuteInterval % 60;
  var selected = TimeOfDay(hour: initialTime.hour, minute: roundedMinute);
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: context.palette.bgElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(GatesRadius.radius24),
      ),
    ),
    builder: (context) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.l10n.commonCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(selected),
                child: Text(context.l10n.commonDone),
              ),
            ],
          ),
          SizedBox(
            height: 216,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: GatesTypography.headingSmall
                      .copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: false,
                minuteInterval: minuteInterval,
                initialDateTime: DateTime(
                  2000,
                  1,
                  1,
                  selected.hour,
                  selected.minute,
                ),
                onDateTimeChanged: (value) {
                  selected = TimeOfDay(hour: value.hour, minute: value.minute);
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

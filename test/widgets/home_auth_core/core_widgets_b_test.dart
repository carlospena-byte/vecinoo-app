import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/widgets/gates_button.dart';
import 'package:gates_app/core/widgets/gates_calendar.dart';
import 'package:gates_app/core/widgets/gates_phone_field.dart';
import 'package:gates_app/core/widgets/gates_select_field.dart';
import 'package:gates_app/core/widgets/gates_sheet.dart';
import 'package:gates_app/core/widgets/gates_text_area.dart';
import 'package:gates_app/core/widgets/gates_text_field.dart';
import 'package:gates_app/core/widgets/gates_time_picker.dart';
import 'package:gates_app/core/widgets/otp_code_field.dart';
import 'package:gates_app/core/widgets/swipe_to_confirm.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../helpers/fonts.dart';
import '_host.dart';

final _es = AppLocalizationsEs();

void main() {
  setUpAll(() async {
    await loadManrope();
    await initializeDateFormatting('es');
  });

  group('GatesTextField', () {
    testWidgets('helper, then validation error after interaction', (
      tester,
    ) async {
      final controller = TextEditingController();
      String? changed;
      await pumpHosted(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: GatesTextField(
            label: 'Nombre',
            helperText: 'Tu nombre',
            controller: controller,
            validator: (v) => (v ?? '').isEmpty ? 'Requerido' : null,
            onChanged: (v) => changed = v,
          ),
        ),
      );
      expect(find.text('Tu nombre'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump();
      expect(changed, 'a');
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(find.text('Requerido'), findsOneWidget);
      expect(find.text('Tu nombre'), findsNothing);
    });

    testWidgets('external errorText wins and focus changes the border', (
      tester,
    ) async {
      await pumpHosted(
        tester,
        const Padding(
          padding: EdgeInsets.all(16),
          child: GatesTextField(label: 'Correo', errorText: 'Invalido'),
        ),
        mode: ThemeMode.dark,
      );
      expect(find.text('Invalido'), findsOneWidget);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(find.text('Invalido'), findsOneWidget);
    });

    testWidgets('focus without error and disabled states', (tester) async {
      await pumpHosted(
        tester,
        const Column(
          children: [
            GatesTextField(label: 'Uno', hintText: 'hint'),
            GatesTextField(label: 'Dos', enabled: false, obscureText: true),
          ],
        ),
      );
      await tester.tap(find.byType(TextField).first);
      await tester.pump();
      expect(find.text('hint'), findsOneWidget);
      final disabled = tester.widget<TextField>(find.byType(TextField).last);
      expect(disabled.enabled, isFalse);
    });
  });

  testWidgets('GatesTextArea shows the counter and updates it', (tester) async {
    final controller = TextEditingController();
    await pumpHosted(
      tester,
      GatesTextArea(controller: controller, maxLength: 50),
    );
    expect(find.text('0/50'), findsOneWidget);
    expect(find.text(_es.commonDoormanNotesLabel), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'hola');
    await tester.pump();
    expect(find.text('4/50'), findsOneWidget);
  });

  group('GatesButton', () {
    testWidgets('styles, loading and disabled', (tester) async {
      var taps = 0;
      await pumpHosted(
        tester,
        Column(
          children: [
            for (final style in GatesButtonStyle.values)
              GatesButton(
                label: style.name,
                style: style,
                onPressed: () => taps++,
              ),
            GatesButton(
              label: 'cargando',
              loading: true,
              onPressed: () => taps++,
            ),
            const GatesButton(label: 'off', onPressed: null),
          ],
        ),
        settle: false,
      );
      await tester.pump();
      await tester.tap(find.text('primary'));
      await tester.tap(find.text('secondary'));
      await tester.tap(find.text('destructive'));
      expect(taps, 3);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('GatesPhoneField', () {
    testWidgets('picks a country and validates', (tester) async {
      final controller = TextEditingController();
      var country = gatesCountryCodes.first;
      final key = GlobalKey<FormState>();
      await pumpHosted(
        tester,
        StatefulBuilder(
          builder: (context, setState) => Form(
            key: key,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GatesPhoneField(
                controller: controller,
                country: country,
                onCountryChanged: (c) => setState(() => country = c),
                validator: (v) => (v ?? '').isEmpty ? 'Falta' : null,
              ),
            ),
          ),
        ),
      );
      expect(find.text('+504'), findsOneWidget);
      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Falta'), findsOneWidget);

      // Only digits, spaces and dashes get through.
      await tester.enterText(find.byType(TextField), '12ab-34');
      await tester.pump();
      expect(controller.text, '12-34');

      await tester.tap(find.bySemanticsLabel(_es.commonCountryCode('+504')));
      await tester.pumpAndSettle();
      expect(find.text(_es.commonCountry), findsOneWidget);
      expect(find.text(_es.commonCountryMexico), findsOneWidget);
      await tester.tap(find.text(_es.commonCountryMexico));
      await tester.pumpAndSettle();
      expect(country.dialCode, '+52');
      expect(find.text('+52'), findsOneWidget);
    });

    testWidgets('closing the sheet keeps the country; localized names', (
      tester,
    ) async {
      final changes = <GatesCountryCode>[];
      await pumpHosted(
        tester,
        GatesPhoneField(
          controller: TextEditingController(),
          country: gatesCountryCodes.first,
          onCountryChanged: changes.add,
        ),
        mode: ThemeMode.dark,
      );
      await tester.tap(find.bySemanticsLabel(_es.commonCountryCode('+504')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(_es.commonClose));
      await tester.pumpAndSettle();
      expect(changes, isEmpty);

      late BuildContext ctx;
      await pumpHosted(
        tester,
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      );
      final names = [for (final c in gatesCountryCodes) c.localizedName(ctx)];
      expect(names, hasLength(gatesCountryCodes.length));
      expect(
        const GatesCountryCode('x', 'Otro', '+999').localizedName(ctx),
        'Otro',
      );
    });
  });

  group('GatesSelectField', () {
    testWidgets('opens the option sheet and reports the choice', (
      tester,
    ) async {
      var value = 'a';
      await pumpHosted(
        tester,
        StatefulBuilder(
          builder: (context, setState) => GatesSelectField<String>(
            label: 'Tipo',
            value: value,
            options: const {'a': 'Alfa', 'b': 'Beta'},
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      );
      expect(find.text('Alfa'), findsOneWidget);
      await tester.tap(find.text('Alfa'));
      await tester.pumpAndSettle();
      expect(find.byIcon(TablerIcons.check), findsOneWidget);
      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();
      expect(value, 'b');
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('placeholder and dismiss', (tester) async {
      var changed = false;
      await pumpHosted(
        tester,
        GatesSelectField<String?>(
          label: 'Tipo',
          value: null,
          placeholder: 'Elige',
          options: const {'a': 'Alfa'},
          onChanged: (_) => changed = true,
        ),
      );
      expect(find.text('Elige'), findsOneWidget);
      await tester.tap(find.text('Elige'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(_es.commonClose));
      await tester.pumpAndSettle();
      expect(changed, isFalse);
    });
  });

  testWidgets('showGatesSheet shows a header with a close button', (
    tester,
  ) async {
    late BuildContext ctx;
    await pumpHosted(
      tester,
      Builder(
        builder: (context) {
          ctx = context;
          return const SizedBox();
        },
      ),
    );
    final future = showGatesSheet<int>(
      ctx,
      (_) => const GatesSheetHeader(title: 'Titulo'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Titulo'), findsOneWidget);
    await tester.tap(find.byTooltip(_es.commonClose));
    await tester.pumpAndSettle();
    expect(await future, isNull);
  });

  group('calendar', () {
    testWidgets('showGatesDatePicker returns the chosen day', (tester) async {
      late BuildContext ctx;
      await pumpHosted(
        tester,
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      );
      final now = DateTime.now();
      final initial = DateTime.utc(now.year + 1, 6, 10);
      final future = showGatesDatePicker(
        ctx,
        initialDate: initial,
        firstDate: DateTime.utc(now.year + 1, 1, 1),
        lastDate: DateTime.utc(now.year + 2, 12, 31),
        title: 'Elige fecha',
        primaryLabel: 'Ok',
      );
      await tester.pumpAndSettle();
      expect(find.text('Elige fecha'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);
      await tester.tap(find.text('15').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();
      final picked = await future;
      expect(picked?.day, 15);
    });

    testWidgets('default labels, close returns null, month title', (
      tester,
    ) async {
      late BuildContext ctx;
      await pumpHosted(
        tester,
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
        mode: ThemeMode.dark,
      );
      final now = DateTime.now();
      final future = showGatesDatePicker(
        ctx,
        initialDate: now,
        firstDate: now.subtract(const Duration(days: 400)),
        lastDate: now.add(const Duration(days: 400)),
      );
      await tester.pumpAndSettle();
      expect(find.text(_es.commonDate), findsOneWidget);
      expect(find.text(_es.commonContinue), findsOneWidget);
      await tester.tap(find.byIcon(TablerIcons.chevronRight));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(_es.commonClose));
      await tester.pumpAndSettle();
      expect(await future, isNull);
    });

    testWidgets('GatesCalendar honours enabledDayPredicate', (tester) async {
      final selections = <DateTime>[];
      final day = DateTime.utc(2030, 5, 10);
      await pumpHosted(
        tester,
        SingleChildScrollView(
          child: GatesCalendar(
            selectedDay: day,
            focusedDay: day,
            firstDay: DateTime.utc(2030, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            enabledDayPredicate: (d) => d.day != 20,
            onDaySelected: (s, f) => selections.add(s),
          ),
        ),
      );
      expect(find.text('Mayo 2030'), findsOneWidget);
      await tester.tap(find.text('20'));
      await tester.pump();
      expect(selections, isEmpty);
      await tester.tap(find.text('21'));
      await tester.pump();
      expect(selections.single.day, 21);
    });
  });

  group('showGatesTimePicker', () {
    testWidgets('done returns the (rounded) initial time', (tester) async {
      late BuildContext ctx;
      await pumpHosted(
        tester,
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      );
      final future = showGatesTimePicker(
        ctx,
        initialTime: const TimeOfDay(hour: 9, minute: 52),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(_es.commonDone));
      await tester.pumpAndSettle();
      expect(await future, const TimeOfDay(hour: 9, minute: 50));
    });

    testWidgets('dragging the wheel changes the time; cancel returns null', (
      tester,
    ) async {
      late BuildContext ctx;
      await pumpHosted(
        tester,
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
        mode: ThemeMode.dark,
      );
      var future = showGatesTimePicker(
        ctx,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(ListWheelScrollView).first,
        const Offset(0, -80),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(_es.commonDone));
      await tester.pumpAndSettle();
      expect(await future, isNot(const TimeOfDay(hour: 10, minute: 0)));

      future = showGatesTimePicker(
        ctx,
        initialTime: const TimeOfDay(hour: 23, minute: 58),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(_es.commonCancel));
      await tester.pumpAndSettle();
      expect(await future, isNull);
    });
  });

  group('OtpCodeField', () {
    testWidgets('typing fills boxes and completes once', (tester) async {
      final controller = TextEditingController();
      final completed = <String>[];
      await pumpHosted(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: OtpCodeField(
            controller: controller,
            label: 'Codigo',
            helper: 'Ayuda',
            onCompleted: completed.add,
          ),
        ),
      );
      expect(find.text('Ayuda'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '12a34');
      await tester.pump();
      expect(controller.text, '1234');
      expect(find.text('1'), findsOneWidget);
      expect(completed, isEmpty);
      await tester.enterText(find.byType(TextField), '123456789');
      await tester.pump();
      expect(controller.text, '123456');
      expect(completed, ['123456']);

      // Moving the caret does not re-complete.
      controller.selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();
      expect(completed, hasLength(1));
    });

    testWidgets('tapping boxes selects them and shows errors', (tester) async {
      final controller = TextEditingController(text: '123');
      await pumpHosted(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: OtpCodeField(
            controller: controller,
            label: 'Codigo',
            errorText: 'Incorrecto',
          ),
        ),
      );
      expect(find.text('Incorrecto'), findsOneWidget);
      // Tap on the 2nd (filled) box.
      await tester.tap(find.text('2'));
      await tester.pump();
      expect(controller.selection.start, 1);
      expect(controller.selection.end, 2);
      // Tap an empty box: caret at end.
      final boxes = find.byType(GestureDetector);
      await tester.tap(
        boxes.at(boxes.evaluate().length - 2),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(controller.selection.isValid, isTrue);
    });

    testWidgets('alphanumeric uppercases and filters', (tester) async {
      final controller = TextEditingController();
      await pumpHosted(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: OtpCodeField(
            controller: controller,
            label: 'Invitacion',
            length: 8,
            alphanumeric: true,
            accentColor: Colors.orange,
          ),
        ),
        mode: ThemeMode.dark,
      );
      await tester.enterText(find.byType(TextField), 'ab-c1');
      await tester.pump();
      expect(controller.text, 'ABC1');
    });
  });

  group('SwipeToConfirm', () {
    Future<void> pump(
      WidgetTester tester, {
      required VoidCallback onConfirmed,
      bool loading = false,
      double threshold = 1.0,
    }) => pumpHosted(
      tester,
      Padding(
        padding: const EdgeInsets.all(16),
        child: SwipeToConfirm(
          label: 'Desliza',
          loading: loading,
          confirmThreshold: threshold,
          onConfirmed: onConfirmed,
        ),
      ),
    );

    testWidgets('full drag confirms once', (tester) async {
      var confirmed = 0;
      await pump(tester, onConfirmed: () => confirmed++);
      await tester.drag(
        find.byIcon(TablerIcons.chevronRight),
        const Offset(400, 0),
      );
      await tester.pumpAndSettle();
      expect(confirmed, 1);
      // Locked: more drags do nothing.
      await tester.drag(
        find.byIcon(TablerIcons.chevronRight),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();
      expect(confirmed, 1);
    });

    testWidgets('short drag snaps back', (tester) async {
      var confirmed = 0;
      await pump(tester, onConfirmed: () => confirmed++);
      await tester.drag(
        find.byIcon(TablerIcons.chevronRight),
        const Offset(80, 0),
      );
      await tester.pumpAndSettle();
      expect(confirmed, 0);
      expect(find.text('Desliza'), findsOneWidget);
    });

    testWidgets('lower threshold confirms earlier', (tester) async {
      var confirmed = 0;
      await pump(tester, onConfirmed: () => confirmed++, threshold: 0.3);
      await tester.drag(
        find.byIcon(TablerIcons.chevronRight),
        const Offset(150, 0),
      );
      await tester.pumpAndSettle();
      expect(confirmed, 1);
    });

    testWidgets('semantic tap confirms without dragging', (tester) async {
      var confirmed = 0;
      final handle = tester.ensureSemantics();
      await pump(tester, onConfirmed: () => confirmed++);
      tester.semantics.tap(find.semantics.byLabel('Desliza'));
      await tester.pumpAndSettle();
      expect(confirmed, 1);
      tester.semantics.tap(find.semantics.byLabel('Desliza'));
      await tester.pump();
      expect(confirmed, 1);
      handle.dispose();
    });

    testWidgets('loading ignores input; releasing loading resets the thumb', (
      tester,
    ) async {
      var confirmed = 0;
      var loading = false;
      late StateSetter update;
      await pumpHosted(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SwipeToConfirm(
                label: 'Desliza',
                loading: loading,
                onConfirmed: () => confirmed++,
              ),
            );
          },
        ),
      );
      await tester.drag(
        find.byIcon(TablerIcons.chevronRight),
        const Offset(400, 0),
      );
      await tester.pumpAndSettle();
      expect(confirmed, 1);

      update(() => loading = true);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.drag(
        find.byType(CircularProgressIndicator),
        const Offset(-300, 0),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(confirmed, 1);

      // Fails without closing: the thumb is handed back and works again.
      update(() => loading = false);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byIcon(TablerIcons.chevronRight),
        const Offset(400, 0),
      );
      await tester.pumpAndSettle();
      expect(confirmed, 2);
    });
  });
}

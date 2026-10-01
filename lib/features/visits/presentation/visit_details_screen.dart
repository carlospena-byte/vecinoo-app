import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_segmented_tabs.dart';
import '../../../core/widgets/gates_sheet.dart';
import '../../../core/widgets/state_views.dart';
import 'providers_catalog_controller.dart';
import '../../../core/widgets/gates_text_field.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/provider_catalog_item.dart';
import '../domain/visit.dart';
import 'visits_controller.dart';
import '../../../core/widgets/gates_toast.dart';

const _notesMaxLength = 120;

/// Args for [VisitDetailsScreen]: either a catalog [provider] was picked in
/// [SelectProviderScreen], or the resident chose "Otro" / a no-results
/// fallback, in which case [provider] is null and the screen asks for a
/// free-text name instead.
class VisitDetailsArgs {
  const VisitDetailsArgs({required this.kind, this.provider});

  final ProviderKind kind;
  final ProviderCatalogItem? provider;
}

String _dateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final day = DateTime(date.year, date.month, date.day);
  final formatted = DateFormat('d MMM y', 'es').format(date);
  if (day == today) return 'Hoy, $formatted';
  if (day == tomorrow) return 'Mañana, $formatted';
  return formatted;
}

String _timeLabel(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// "Octubre 2026" — capitalized month name plus year (see
/// booking_date_time_sheet.dart for the same helper in the amenities flow).
String _monthTitle(DateTime date) {
  final month = DateFormat('MMMM', 'es').format(date);
  return '${month[0].toUpperCase()}${month.substring(1)} ${date.year}';
}

Future<DateTime?> _showVisitDateSheet(BuildContext context, DateTime initial) {
  var selectedDay = initial;
  var focusedDay = initial;
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(GatesRadius.radius24),
      ),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        top: false,
        child: Padding(
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
              const SizedBox(height: GatesSpacing.space16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(GatesSpacing.space16),
                decoration: BoxDecoration(
                  color: context.palette.bgSurface,
                  borderRadius: BorderRadius.circular(GatesRadius.radius24),
                ),
                child: TableCalendar(
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  firstDay: DateTime.now().subtract(const Duration(days: 1)),
                  lastDay: DateTime.now().add(const Duration(days: 180)),
                  focusedDay: focusedDay,
                  locale: 'es',
                  daysOfWeekHeight: 24,
                  rowHeight: 44,
                  selectedDayPredicate: (day) => isSameDay(day, selectedDay),
                  onDaySelected: (selected, focused) {
                    setSheetState(() {
                      selectedDay = selected;
                      focusedDay = focused;
                    });
                  },
                  enabledDayPredicate: (day) => !day.isBefore(
                    DateTime.now().subtract(const Duration(days: 1)),
                  ),
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
                        BorderSide(
                          color: context.palette.borderSelectedBrand,
                          width: 2,
                        ),
                      ),
                    ),
                    selectedTextStyle: GatesTypography.body.copyWith(
                      color: context.palette.textOnBrand,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: GatesSpacing.space24),
              SizedBox(
                width: double.infinity,
                child: GatesButton(
                  label: 'Continuar',
                  onPressed: () => Navigator.of(context).pop(selectedDay),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// A scrolling-wheel time picker, matching the one in
/// booking_date_time_sheet.dart's amenities flow.
Future<TimeOfDay?> _showArrivalTimeSheet(
  BuildContext context,
  TimeOfDay initial,
) {
  var selected = initial;
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
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(selected),
                child: const Text('Listo'),
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
                use24hFormat: true,
                minuteInterval: 5,
                initialDateTime: DateTime(
                  2000,
                  1,
                  1,
                  initial.hour,
                  initial.minute,
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

/// Merges Figma's "D01 · Entrega" (`119:371`, delivery/paquetería — has a
/// "Hora de llegada" field) and "D02 · Proveedor" (`339:3037`, proveedor —
/// has a free-text "Nombre de la visita" instead) into one screen, since
/// they only differ in those two fields.
class VisitDetailsScreen extends ConsumerStatefulWidget {
  const VisitDetailsScreen({super.key, required this.args});

  final VisitDetailsArgs args;

  @override
  ConsumerState<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends ConsumerState<VisitDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _visitDate = DateTime.now();
  TimeOfDay? _arrivalTime = TimeOfDay.now();
  bool _notifyOnArrival = true;
  bool _isSubmitting = false;

  // Start from what the catalog screen passed, but let the resident change it
  // here (via the "¿Quién viene?" sheet) if they picked the wrong one.
  late ProviderCatalogItem? _provider = widget.args.provider;
  late ProviderKind _kind = widget.args.kind;

  @override
  void initState() {
    super.initState();
    // Arrived via "Otro": go straight to typing the name.
    if (_provider == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _changeProvider();
      });
    }
  }

  bool get _needsTime => _kind != ProviderKind.proveedor;

  Future<void> _changeProvider() async {
    final membership = ref.read(selectedMembershipProvider).value;
    if (membership == null) return;
    final result = await showGatesSheet<_ProviderChoice>(
      context,
      (_) => _ProviderSheet(
        residentialId: membership.residentialId,
        initialKind: _kind,
        selectedId: _provider?.id,
        customName: _provider == null ? _nameController.text.trim() : '',
      ),
    );
    if (result == null) return;
    setState(() {
      _provider = result.provider;
      _kind = result.kind;
      if (result.provider == null) _nameController.text = result.customName;
    });
  }

  Future<void> _pickDate() async {
    final picked = await _showVisitDateSheet(context, _visitDate);
    if (picked != null) setState(() => _visitDate = picked);
  }

  Future<void> _pickArrivalTime() async {
    final picked = await _showArrivalTimeSheet(
      context,
      _arrivalTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _arrivalTime = picked);
  }

  Future<void> _submit() async {
    final provider = _provider;
    if (provider == null && _nameController.text.trim().isEmpty) {
      _changeProvider();
      return;
    }

    final membership = ref.read(selectedMembershipProvider).value;
    if (membership == null) return;

    setState(() => _isSubmitting = true);
    try {
      final arrivalDateTime = _arrivalTime == null
          ? null
          : DateTime(
              _visitDate.year,
              _visitDate.month,
              _visitDate.day,
              _arrivalTime!.hour,
              _arrivalTime!.minute,
            );
      await ref
          .read(visitsRepositoryProvider)
          .createDeliveryVisit(
            residentialId: membership.residentialId,
            unitId: membership.unitId,
            name: provider?.name ?? _nameController.text.trim(),
            providerKind: _kind,
            visitDate: _visitDate,
            arrivalTime: _needsTime ? arrivalDateTime : null,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      showGatesToast(
        context,
        type: GatesToastType.success,
        title: 'Visita autorizada',
      );
    } catch (_) {
      if (mounted) {
        showGatesToast(
          context,
          type: GatesToastType.error,
          title: 'No pudimos autorizar la visita',
          message: 'Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GatesSpacing.space24,
                GatesSpacing.space16,
                GatesSpacing.space24,
                0,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_back, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: GatesSpacing.space12),
                  Text(
                    'Detalles de la visita',
                    style: GatesTypography.headingMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    GatesSpacing.space24,
                    0,
                    GatesSpacing.space24,
                    GatesSpacing.space16,
                  ),
                  children: [
                    _SelectedCatalogField(
                      label: _kind == ProviderKind.proveedor
                          ? 'Servicio'
                          : '¿Quién viene?',
                      value:
                          provider?.name ??
                          (_nameController.text.trim().isEmpty
                              ? 'Otro'
                              : _nameController.text.trim()),
                      onTap: _changeProvider,
                    ),
                    const SizedBox(height: GatesSpacing.space16),
                    _PickerField(
                      label: 'Fecha de visita',
                      value: _dateLabel(_visitDate),
                      icon: Icons.calendar_today_outlined,
                      helper: 'Acceso válido durante el día seleccionado.',
                      onTap: _pickDate,
                    ),
                    if (_needsTime) ...[
                      const SizedBox(height: GatesSpacing.space16),
                      _PickerField(
                        label: 'Horario',
                        value: _arrivalTime == null
                            ? 'Elige una hora'
                            : _timeLabel(_arrivalTime!),
                        icon: Icons.access_time,
                        onTap: _pickArrivalTime,
                      ),
                    ],
                    const SizedBox(height: GatesSpacing.space16),
                    _NotesField(controller: _notesController),
                    const SizedBox(height: GatesSpacing.space16),
                    _NotifySwitch(
                      value: _notifyOnArrival,
                      onChanged: (v) => setState(() => _notifyOnArrival = v),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GatesSpacing.space24,
                0,
                GatesSpacing.space24,
                GatesSpacing.space24,
              ),
              child: SizedBox(
                width: double.infinity,
                child: GatesButton(
                  label: 'Autorizar visita',
                  loading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Selected catalog" field — Figma node `I119:380;24:15`: read-only, tap
/// to go back and change the catalog pick.
class _SelectedCatalogField extends StatelessWidget {
  const _SelectedCatalogField({
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
      borderRadius: BorderRadius.circular(GatesRadius.radius16),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(
          horizontal: GatesSpacing.space16,
          vertical: GatesSpacing.space12,
        ),
        decoration: BoxDecoration(
          color: context.palette.bgSurface,
          border: Border.all(color: context.palette.borderDefault),
          borderRadius: BorderRadius.circular(GatesRadius.radius16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.gatesText.caption),
                  const SizedBox(height: GatesSpacing.space4),
                  Text(value, style: GatesTypography.body),
                ],
              ),
            ),
            Icon(
              Icons.expand_more,
              size: 20,
              color: context.palette.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Date picker / IFTA" and "Time picker / IFTA" fields — Figma nodes
/// `29:87` / `33:115`, unified since they only differ by icon and helper.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.helper,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? helper;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(GatesRadius.radius16),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(
              horizontal: GatesSpacing.space16,
              vertical: GatesSpacing.space12,
            ),
            decoration: BoxDecoration(
              color: context.palette.bgSurface,
              border: Border.all(color: context.palette.borderDefault),
              borderRadius: BorderRadius.circular(GatesRadius.radius16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: context.gatesText.caption),
                      const SizedBox(height: GatesSpacing.space4),
                      Text(value, style: GatesTypography.body),
                    ],
                  ),
                ),
                Icon(icon, size: 20, color: context.palette.textBrand),
              ],
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: GatesSpacing.space8),
          Text(helper!, style: context.gatesText.caption),
        ],
      ],
    );
  }
}

/// "Textarea / IFTA" — Figma node `26:6`.
class _NotesField extends StatefulWidget {
  const _NotesField({required this.controller});

  final TextEditingController controller;

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(GatesSpacing.space16),
          decoration: BoxDecoration(
            color: context.palette.bgSurface,
            border: Border.all(color: context.palette.borderDefault),
            borderRadius: BorderRadius.circular(GatesRadius.radius16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notas para portería (opcional)',
                style: context.gatesText.caption,
              ),
              const SizedBox(height: GatesSpacing.space8),
              TextField(
                controller: widget.controller,
                maxLines: 3,
                maxLength: _notesMaxLength,
                buildCounter: (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => null,
                decoration: const InputDecoration(
                  isDense: true,
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Agrega una indicación',
                  hintStyle: GatesTypography.body,
                ),
                style: GatesTypography.body,
              ),
            ],
          ),
        ),
        const SizedBox(height: GatesSpacing.space8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${widget.controller.text.length}/$_notesMaxLength',
            style: context.gatesText.caption,
          ),
        ),
      ],
    );
  }
}

/// "Switch" — Figma node `24:185`.
class _NotifySwitch extends StatelessWidget {
  const _NotifySwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(GatesRadius.radius16),
      onTap: () => onChanged(!value),
      child: Container(
        height: 88,
        padding: const EdgeInsets.all(GatesSpacing.space16),
        decoration: BoxDecoration(
          color: context.palette.bgSurface,
          border: Border.all(color: context.palette.borderDefault),
          borderRadius: BorderRadius.circular(GatesRadius.radius16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Avisarme al llegar', style: GatesTypography.label),
                  const SizedBox(height: GatesSpacing.space4),
                  Text(
                    'Notificaciones de mis visitas',
                    style: context.gatesText.caption,
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: context.palette.bgBrand,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderChoice {
  const _ProviderChoice(this.kind, this.provider, [this.customName = '']);

  final ProviderKind kind;

  /// Null means "Otro": the resident typed [customName] instead.
  final ProviderCatalogItem? provider;
  final String customName;
}

/// Bottom sheet listing every catalog option (with kind tabs) plus an "Otro"
/// entry that expands an input for a custom name, so a wrong "¿Quién viene?"
/// pick can be changed without going back.
class _ProviderSheet extends ConsumerStatefulWidget {
  const _ProviderSheet({
    required this.residentialId,
    required this.initialKind,
    required this.selectedId,
    required this.customName,
  });

  final String residentialId;
  final ProviderKind initialKind;
  final String? selectedId;

  /// Name already typed under "Otro" (empty if none).
  final String customName;

  @override
  ConsumerState<_ProviderSheet> createState() => _ProviderSheetState();
}

class _ProviderSheetState extends ConsumerState<_ProviderSheet> {
  late ProviderKind _kind = widget.initialKind;
  late final _nameController = TextEditingController(text: widget.customName);

  /// Whether "Otro" is expanded. Starts open when nothing from the catalog is
  /// selected (arrived via "Otro", or already using a custom name).
  late bool _otherOpen = widget.selectedId == null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _confirmOther() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(_ProviderChoice(_kind, null, name));
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(
      providersCatalogProvider((
        residentialId: widget.residentialId,
        kind: _kind,
      )),
    );
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: (MediaQuery.sizeOf(context).height * 0.75 - keyboard)
              .clamp(320.0, double.infinity),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: GatesSpacing.space24)
              .copyWith(bottom: GatesSpacing.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GatesSheetHeader(title: 'Cambiar visita'),
              const SizedBox(height: GatesSpacing.space8),
              GatesSegmentedTabs<ProviderKind>(
                options: [
                  for (final kind in ProviderKind.values)
                    GatesSegmentedTabOption(
                      value: kind,
                      label: providerKindLabel(kind),
                    ),
                ],
                selected: _kind,
                onSelect: (kind) => setState(() => _kind = kind),
              ),
              const SizedBox(height: GatesSpacing.space8),
              Expanded(
                child: catalogAsync.when(
                  loading: () => const LoadingView(),
                  error: (e, _) => ErrorView(
                    message: 'No pudimos cargar el catálogo.',
                    onRetry: () => ref.invalidate(
                      providersCatalogProvider((
                        residentialId: widget.residentialId,
                        kind: _kind,
                      )),
                    ),
                  ),
                  data: (items) => ListView(
                    children: [
                      for (final item in items)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: context.palette.bgSubtle,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              providerInitials(item.name),
                              style: GatesTypography.label.copyWith(
                                color: context.palette.textBrand,
                              ),
                            ),
                          ),
                          title: Text(item.name, style: GatesTypography.body),
                          trailing: item.id == widget.selectedId
                              ? Icon(
                                  Icons.check,
                                  color: context.palette.textBrand,
                                )
                              : null,
                          onTap: () =>
                              Navigator.of(context)
                                  .pop(_ProviderChoice(_kind, item)),
                        ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(Icons.edit_outlined),
                        ),
                        title: Text('Otro', style: GatesTypography.body),
                        trailing: Icon(
                          _otherOpen ? Icons.expand_less : Icons.expand_more,
                          color: context.palette.textSecondary,
                        ),
                        onTap: () => setState(() => _otherOpen = !_otherOpen),
                      ),
                      if (_otherOpen) ...[
                        GatesTextField(
                          label: 'Nombre de la visita *',
                          hintText: 'Escribe el nombre',
                          autofocus: true,
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: GatesSpacing.space16),
                        GatesButton(
                          label: 'Usar este nombre',
                          onPressed: _nameController.text.trim().isEmpty
                              ? null
                              : _confirmOther,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

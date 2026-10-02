import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure_messages.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_calendar.dart';
import '../../../core/widgets/gates_sheet.dart';
import '../../../core/widgets/gates_tap_field.dart';
import '../../../core/widgets/gates_text_area.dart';
import '../../../core/widgets/gates_time_picker.dart';
import '../../../core/widgets/gates_toast.dart';
import '../../../l10n/l10n.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/visit.dart';
import 'frequent_visit_formatters.dart';
import 'visit_date_formatters.dart';
import 'visit_details_controller.dart';
import 'visit_provider_sheet.dart';

export 'visit_details_controller.dart' show VisitDetailsArgs;

const _notesMaxLength = 120;

/// Merges Figma's "D01 · Entrega" (`119:371`, delivery/paquetería — has a
/// "Hora de llegada" field) and "D02 · Proveedor" (`339:3037`, proveedor —
/// has a free-text "Nombre de la visita" instead) into one screen, since
/// they only differ in those two fields. State and the authorize call live
/// in [VisitDetailsController].
class VisitDetailsScreen extends ConsumerStatefulWidget {
  const VisitDetailsScreen({super.key, required this.args});

  final VisitDetailsArgs args;

  @override
  ConsumerState<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends ConsumerState<VisitDetailsScreen> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  StreamSubscription<VisitDetailsEvent>? _events;

  VisitDetailsController get _controller =>
      ref.read(visitDetailsControllerProvider(widget.args).notifier);

  @override
  void initState() {
    super.initState();
    _events = _controller.events.listen(_onEvent);
    // Arrived via "Otro": go straight to typing the name.
    if (widget.args.provider == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _changeProvider();
      });
    }
  }

  @override
  void dispose() {
    _events?.cancel();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onEvent(VisitDetailsEvent event) {
    if (!mounted) return;
    final l10n = context.l10n;
    switch (event) {
      case NeedsProvider():
        _changeProvider();
      case VisitAuthorized():
        Navigator.of(context).popUntil((route) => route.isFirst);
        showGatesToast(
          context,
          type: GatesToastType.success,
          title: l10n.visitsDetailsAuthorizedToast,
        );
      case AuthorizeFailed(:final failure):
        final detail = failureDetail(l10n, failure);
        showGatesToast(
          context,
          type: GatesToastType.error,
          title: l10n.visitsDetailsAuthorizeError,
          message: detail == null
              ? l10n.visitsTryAgain
              : '$detail ${l10n.visitsTryAgain}',
        );
    }
  }

  Future<void> _changeProvider() async {
    final membership = ref.read(selectedMembershipProvider).value;
    if (membership == null) return;
    final state = ref.read(visitDetailsControllerProvider(widget.args));
    final result = await showGatesSheet<ProviderChoice>(
      context,
      (_) => ProviderSheet(
        residentialId: membership.residentialId,
        initialKind: state.kind,
        selectedId: state.provider?.id,
        customName: state.provider == null ? _nameController.text.trim() : '',
      ),
    );
    if (result == null) return;
    setState(() {
      if (result.provider == null) _nameController.text = result.customName;
    });
    _controller.changeProvider(result.provider, result.kind);
  }

  Future<void> _pickDate() async {
    // Must be UTC-normalized: TableCalendar normalizes firstDay/lastDay via
    // `DateTime.utc(y, m, d)` internally, so a local-time "today" would sit
    // hours ahead of UTC midnight in negative UTC-offset timezones and make
    // today read as before firstDay (disabled).
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final picked = await showGatesDatePicker(
      context,
      initialDate: ref
          .read(visitDetailsControllerProvider(widget.args))
          .visitDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 180)),
      title: context.l10n.visitsFastlaneVisitDate,
    );
    if (picked != null) _controller.setVisitDate(picked);
  }

  Future<void> _pickArrivalTime() async {
    final current = ref
        .read(visitDetailsControllerProvider(widget.args))
        .arrivalTime;
    final picked = await showGatesTimePicker(
      context,
      initialTime: current ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) _controller.setArrivalTime(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(visitDetailsControllerProvider(widget.args));
    final provider = state.provider;

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
                      tooltip: l10n.visitsBack,
                      padding: EdgeInsets.zero,
                      icon: const Icon(TablerIcons.arrowLeft, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: GatesSpacing.space12),
                  Text(
                    l10n.visitsDetailsTitle,
                    style: GatesTypography.headingMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  GatesSpacing.space24,
                  0,
                  GatesSpacing.space24,
                  GatesSpacing.space16,
                ),
                children: [
                  GatesTapField(
                    label: state.kind == ProviderKind.proveedor
                        ? l10n.visitsDetailsService
                        : l10n.visitsNewTypeTitle,
                    value:
                        provider?.name ??
                        (_nameController.text.trim().isEmpty
                            ? l10n.visitsCatalogOther
                            : _nameController.text.trim()),
                    icon: TablerIcons.chevronDown,
                    iconColor: context.palette.textSecondary,
                    onTap: _changeProvider,
                  ),
                  const SizedBox(height: GatesSpacing.space16),
                  GatesTapField(
                    label: l10n.visitsFastlaneVisitDate,
                    value: formatVisitDate(l10n, state.visitDate),
                    icon: TablerIcons.calendar,
                    helper: l10n.visitsDetailsDateHelper,
                    onTap: _pickDate,
                  ),
                  if (state.needsTime) ...[
                    const SizedBox(height: GatesSpacing.space16),
                    GatesTapField(
                      label: l10n.visitsFrequentScheduleLabel,
                      value: state.arrivalTime == null
                          ? l10n.visitsDetailsPickTime
                          : formatClockText(state.arrivalTime!),
                      icon: TablerIcons.clock,
                      onTap: _pickArrivalTime,
                    ),
                  ],
                  const SizedBox(height: GatesSpacing.space16),
                  GatesTextArea(
                    controller: _notesController,
                    maxLength: _notesMaxLength,
                    label: l10n.visitsDetailsNotesLabel,
                    hintText: l10n.visitsDetailsNotesHint,
                  ),
                ],
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
                  label: l10n.visitsDetailsAuthorize,
                  loading: state.isSubmitting,
                  onPressed: state.isSubmitting
                      ? null
                      : () => _controller.submit(
                          customName: _nameController.text,
                          notes: _notesController.text,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

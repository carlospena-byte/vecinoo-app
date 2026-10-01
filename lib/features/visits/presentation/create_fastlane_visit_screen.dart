import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_calendar.dart';
import '../../../core/widgets/gates_text_area.dart';
import '../../../core/widgets/gates_text_field.dart';
import '../../../core/widgets/gates_time_picker.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/visit.dart';
import 'visits_controller.dart';
import '../../../core/widgets/gates_toast.dart';

const _notesMaxLength = 120;

/// Shared with [VisitPendingDetailScreen] so both show identical date text.
String formatVisitDate(DateTime date) {
  final now = DateTime.now();
  final isToday =
      date.year == now.year && date.month == now.month && date.day == now.day;
  final formatted = DateFormat('d MMM y', 'es').format(date);
  return isToday ? 'Hoy, $formatted' : formatted;
}

String formatArrivalTime(TimeOfDay time) {
  final asDateTime = DateTime(2000, 1, 1, time.hour, time.minute);
  return DateFormat('h:mm a', 'es').format(asDateTime);
}

/// FastLane invite flow — Figma "10 · Visitas / FastLane residente"
/// (node 116:186). F01 asks for a reference name, visit date and expected
/// arrival time; on success it swaps in F02, showing the self-registration
/// link the resident shares themselves via the OS share sheet (F03) instead
/// of a backend-sent SMS/WhatsApp message.
class CreateFastlaneVisitScreen extends ConsumerStatefulWidget {
  const CreateFastlaneVisitScreen({super.key, this.editing});

  /// When set, the form is prefilled from this pending invitation and saving
  /// updates it instead of creating a new one.
  final Visit? editing;

  @override
  ConsumerState<CreateFastlaneVisitScreen> createState() =>
      _CreateFastlaneVisitScreenState();
}

class _CreateFastlaneVisitScreenState
    extends ConsumerState<CreateFastlaneVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _visitDate = DateTime.now();
  TimeOfDay _arrivalTime = TimeOfDay.now();
  bool _isSubmitting = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _nameController.text = editing.name ?? '';
      _notesController.text = editing.notes ?? '';
      _visitDate = editing.validFrom;
      _arrivalTime = TimeOfDay.fromDateTime(editing.validFrom);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickVisitDate() async {
    // Must be UTC-normalized: TableCalendar normalizes firstDay/lastDay via
    // `DateTime.utc(y, m, d)` internally, so a local-time "today" here would
    // sit hours ahead of UTC midnight in negative UTC-offset timezones and
    // make today read as before firstDay (disabled).
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final picked = await showGatesDatePicker(
      context,
      initialDate: _visitDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      title: 'Fecha de visita',
    );
    if (picked != null) setState(() => _visitDate = picked);
  }

  Future<void> _pickArrivalTime() async {
    final picked = await showGatesTimePicker(
      context,
      initialTime: _arrivalTime,
    );
    if (picked != null) setState(() => _arrivalTime = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final membership = ref.read(selectedMembershipProvider).value;
    if (membership == null) return;

    setState(() => _isSubmitting = true);
    final editing = widget.editing;
    if (editing != null) {
      try {
        await ref
            .read(visitsRepositoryProvider)
            .updateFastlaneVisit(
              visitId: editing.id,
              name: _nameController.text.trim(),
              visitDate: _visitDate,
              arrivalTime: _arrivalTime,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );
        if (!mounted) return;
        context.pop();
        showGatesToast(
          context,
          type: GatesToastType.success,
          title: 'Invitación actualizada',
        );
      } catch (_) {
        if (mounted) {
          showGatesToast(
            context,
            type: GatesToastType.error,
            title: 'No pudimos guardar los cambios',
            message: 'Intenta de nuevo.',
          );
          setState(() => _isSubmitting = false);
        }
      }
      return;
    }
    try {
      final result = await ref
          .read(visitsRepositoryProvider)
          .createFastlaneVisit(
            residentialId: membership.residentialId,
            unitId: membership.unitId,
            name: _nameController.text.trim(),
            visitDate: _visitDate,
            arrivalTime: _arrivalTime,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      if (!mounted) return;
      // Land on the shared F02 screen (share / copy / edit / cancel) with the
      // visits list underneath, so its back arrow returns to the list.
      final router = GoRouter.of(context);
      router.go('/');
      router.push('/visits/${result.id}?created=1', extra: result);
    } catch (_) {
      if (mounted) {
        showGatesToast(
          context,
          type: GatesToastType.error,
          title: 'No pudimos crear la invitación',
          message: 'Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final membership = ref.watch(selectedMembershipProvider).value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_isEditing ? 'Editar invitación' : 'Invitar con FastLane'),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(GatesSpacing.space24),
            children: [
              if (membership != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('UNIDAD', style: context.gatesText.caption),
                    const SizedBox(height: GatesSpacing.space4),
                    Text(
                      membership.label,
                      style: GatesTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GatesSpacing.space16),
              ],
              GatesTextField(
                controller: _nameController,
                label: 'Nombre de referencia *',
                hintText: 'Visita de...',
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Escribe un nombre para identificar la visita.'
                    : null,
              ),
              const SizedBox(height: GatesSpacing.space16),
              _TapField(
                label: 'Fecha de visita',
                value: formatVisitDate(_visitDate),
                helper: 'Fecha prevista para la visita.',
                icon: Icons.calendar_month_outlined,
                onTap: _pickVisitDate,
              ),
              const SizedBox(height: GatesSpacing.space16),
              _TapField(
                label: 'Hora de llegada prevista *',
                value: formatArrivalTime(_arrivalTime),
                onTap: _pickArrivalTime,
              ),
              const SizedBox(height: GatesSpacing.space16),
              GatesTextArea(
                controller: _notesController,
                maxLength: _notesMaxLength,
              ),
              const SizedBox(height: GatesSpacing.space8),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(GatesSpacing.space24),
        child: GatesButton(
          label: _isEditing ? 'Guardar cambios' : 'Crear invitación',
          loading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
        ),
      ),
    );
  }
}

/// "Field / IFTA" style tappable row — used for the date and arrival-time
/// pickers, which show their value like a Field/IFTA but open a native
/// picker on tap instead of accepting keyboard input.
class _TapField extends StatelessWidget {
  const _TapField({
    required this.label,
    required this.value,
    required this.onTap,
    this.helper,
    this.icon,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final String? helper;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(GatesRadius.radius16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: context.palette.bgSurface,
              border: Border.all(color: context.palette.borderDefault),
              borderRadius: BorderRadius.circular(GatesRadius.radius16),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: GatesSpacing.space16,
              vertical: GatesSpacing.space12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: context.gatesText.caption),
                      const SizedBox(height: GatesSpacing.space4),
                      Text(value, style: GatesTypography.body),
                    ],
                  ),
                ),
                if (icon != null)
                  Icon(icon, size: 20, color: context.palette.textBrand),
              ],
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: GatesSpacing.space4),
          Text(helper!, style: context.gatesText.caption),
        ],
      ],
    );
  }
}

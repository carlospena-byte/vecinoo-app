import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../session/presentation/session_controller.dart';
import '../domain/visit.dart';
import 'visits_controller.dart';

const _notesMaxLength = 120;
const _dayLabels = {'mon': 'Lun', 'tue': 'Mar', 'wed': 'Mié', 'thu': 'Jue', 'fri': 'Vie', 'sat': 'Sáb', 'sun': 'Dom'};

class CreateFrequentVisitScreen extends ConsumerStatefulWidget {
  const CreateFrequentVisitScreen({super.key});

  @override
  ConsumerState<CreateFrequentVisitScreen> createState() => _CreateFrequentVisitScreenState();
}

class _CreateFrequentVisitScreenState extends ConsumerState<CreateFrequentVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _plateController = TextEditingController();
  final _notesController = TextEditingController();

  VisitorRole _role = VisitorRole.familiar;
  Recurrence _recurrence = Recurrence.daily;
  ScheduleType _scheduleType = ScheduleType.allDay;
  TimeOfDay _scheduleStart = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _scheduleEnd = const TimeOfDay(hour: 20, minute: 0);
  final Set<String> _selectedDays = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _plateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_recurrence == Recurrence.custom && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un día')),
      );
      return;
    }
    final membership = ref.read(selectedMembershipProvider).value;
    if (membership == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(visitsRepositoryProvider).createFrequentVisit(
            residentialId: membership.residentialId,
            unitId: membership.unitId,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            plate: _plateController.text.trim().isEmpty ? null : _plateController.text.trim(),
            visitorRole: _role,
            recurrence: _recurrence,
            recurrenceDays: _recurrence == Recurrence.custom ? _selectedDays.toList() : null,
            scheduleType: _scheduleType,
            scheduleStart: _scheduleType == ScheduleType.custom ? _formatTime(_scheduleStart) : null,
            scheduleEnd: _scheduleType == ScheduleType.custom ? _formatTime(_scheduleEnd) : null,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visita frecuente autorizada')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo autorizar. Intenta de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visita frecuente')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre de la visita'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<VisitorRole>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: VisitorRole.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(visitorRoleLabel(r))))
                    .toList(),
                onChanged: (v) => setState(() => _role = v ?? VisitorRole.familiar),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(labelText: 'Placa (opcional)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Recurrence>(
                initialValue: _recurrence,
                decoration: const InputDecoration(labelText: 'Frecuenta'),
                items: Recurrence.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(recurrenceLabel(r))))
                    .toList(),
                onChanged: (v) => setState(() => _recurrence = v ?? Recurrence.daily),
              ),
              if (_recurrence == Recurrence.custom) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _dayLabels.entries.map((entry) {
                    final selected = _selectedDays.contains(entry.key);
                    return FilterChip(
                      label: Text(entry.value),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        if (v) {
                          _selectedDays.add(entry.key);
                        } else {
                          _selectedDays.remove(entry.key);
                        }
                      }),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<ScheduleType>(
                initialValue: _scheduleType,
                decoration: const InputDecoration(labelText: 'Horario'),
                items: const [
                  DropdownMenuItem(value: ScheduleType.allDay, child: Text('Todo el día')),
                  DropdownMenuItem(value: ScheduleType.custom, child: Text('Personalizado')),
                ],
                onChanged: (v) => setState(() => _scheduleType = v ?? ScheduleType.allDay),
              ),
              if (_scheduleType == ScheduleType.custom) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: _scheduleStart);
                          if (picked != null) setState(() => _scheduleStart = picked);
                        },
                        child: Text('Desde ${_scheduleStart.format(context)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: _scheduleEnd);
                          if (picked != null) setState(() => _scheduleEnd = picked);
                        },
                        child: Text('Hasta ${_scheduleEnd.format(context)}'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notas para la portería'),
                maxLength: _notesMaxLength,
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Autorizar visita'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

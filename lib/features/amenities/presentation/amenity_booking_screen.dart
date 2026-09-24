import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../session/presentation/session_controller.dart';
import '../data/amenities_repository.dart';
import '../domain/amenity.dart';
import 'amenities_controller.dart';

class AmenityBookingScreen extends ConsumerStatefulWidget {
  const AmenityBookingScreen({super.key, required this.amenity});

  final Amenity amenity;

  @override
  ConsumerState<AmenityBookingScreen> createState() => _AmenityBookingScreenState();
}

class _AmenityBookingScreenState extends ConsumerState<AmenityBookingScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  final _notesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  DateTime _combine(DateTime day, TimeOfDay time) {
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _submit() async {
    final start = _combine(_selectedDay, _startTime);
    final end = _combine(_selectedDay, _endTime);

    if (!end.isAfter(start)) {
      _showError('La hora de fin debe ser después de la hora de inicio.');
      return;
    }
    if (start.isBefore(DateTime.now())) {
      _showError('Elige un horario en el futuro.');
      return;
    }

    final membership = ref.read(selectedMembershipProvider).value;
    if (membership == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(amenitiesRepositoryProvider).createBooking(
            amenityId: widget.amenity.id,
            residentialId: membership.residentialId,
            unitId: membership.unitId,
            startTime: start,
            endTime: end,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
      ref.invalidate(myBookingsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva enviada')),
      );
    } on BookingConflictException {
      _showError('Ese horario ya no está disponible. Elige otro.');
    } catch (_) {
      _showError('No se pudo crear la reserva. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.amenity.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.amenity.description != null) ...[
              Text(widget.amenity.description!),
              const SizedBox(height: 12),
            ],
            Card(
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 1)),
                lastDay: DateTime.now().add(const Duration(days: 180)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                enabledDayPredicate: (day) =>
                    !day.isBefore(DateTime.now().subtract(const Duration(days: 1))),
                calendarFormat: CalendarFormat.month,
                headerStyle: const HeaderStyle(titleCentered: true, formatButtonVisible: false),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(isStart: true),
                    child: Text('Inicio: ${_startTime.format(context)}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(isStart: false),
                    child: Text('Fin: ${_endTime.format(context)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notas (opcional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Reservar'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../session/presentation/session_controller.dart';
import '../domain/visit.dart';
import 'visits_controller.dart';

const _notesMaxLength = 120;

class CreateDeliveryVisitScreen extends ConsumerStatefulWidget {
  const CreateDeliveryVisitScreen({super.key});

  @override
  ConsumerState<CreateDeliveryVisitScreen> createState() => _CreateDeliveryVisitScreenState();
}

class _CreateDeliveryVisitScreenState extends ConsumerState<CreateDeliveryVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _plateController = TextEditingController();
  final _notesController = TextEditingController();

  ProviderKind _providerKind = ProviderKind.delivery;
  DateTime _visitDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _plateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final membership = ref.read(selectedMembershipProvider).value;
    if (membership == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(visitsRepositoryProvider).createDeliveryVisit(
            residentialId: membership.residentialId,
            unitId: membership.unitId,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            plate: _plateController.text.trim().isEmpty ? null : _plateController.text.trim(),
            providerKind: _providerKind,
            visitDate: _visitDate,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visita de delivery agendada')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo agendar. Intenta de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery o Proveedor')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<ProviderKind>(
                initialValue: _providerKind,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: ProviderKind.values
                    .map((k) => DropdownMenuItem(value: k, child: Text(providerKindLabel(k))))
                    .toList(),
                onChanged: (v) => setState(() => _providerKind = v ?? ProviderKind.delivery),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre de la visita'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
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
              OutlinedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _visitDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _visitDate = picked);
                },
                child: Text('Fecha de la visita: ${DateFormat('d MMM y', 'es').format(_visitDate)}'),
              ),
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
                    : const Text('Agendar visita'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

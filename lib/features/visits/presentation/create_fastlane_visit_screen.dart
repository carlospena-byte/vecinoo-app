import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../session/presentation/session_controller.dart';
import 'visits_controller.dart';

class CreateFastlaneVisitScreen extends ConsumerStatefulWidget {
  const CreateFastlaneVisitScreen({super.key});

  @override
  ConsumerState<CreateFastlaneVisitScreen> createState() => _CreateFastlaneVisitScreenState();
}

class _CreateFastlaneVisitScreenState extends ConsumerState<CreateFastlaneVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _visitDate = DateTime.now();
  String _channel = 'whatsapp';
  bool _isSubmitting = false;
  String? _accessCode;
  bool? _notificationSent;
  String? _notificationError;

  @override
  void dispose() {
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final membership = ref.read(selectedMembershipProvider).value;
    if (membership == null) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await ref.read(visitsRepositoryProvider).createFastlaneVisit(
            residentialId: membership.residentialId,
            unitId: membership.unitId,
            phone: _phoneController.text.trim(),
            visitDate: _visitDate,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            channel: _channel,
          );
      if (!mounted) return;
      setState(() {
        _accessCode = result.accessCode;
        _notificationSent = result.notificationSent;
        _notificationError = result.notificationError;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo crear el acceso. Intenta de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_accessCode != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso FastLane creado')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('El visitante recibirá un link para llenar sus propios datos.'),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Código de acceso', style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          _accessCode!,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_notificationSent == false)
                  Text(
                    _notificationError ?? 'No se pudo enviar la notificación.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  )
                else if (_notificationSent == true)
                  const Text('Notificación enviada.'),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _accessCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código copiado')),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copiar código'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Listo'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('FastLane')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Envía un link para que el visitante llene su nombre, placa y foto de identificación.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono de contacto'),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
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
                child: Text('Fecha de visita: ${DateFormat('d MMM y', 'es').format(_visitDate)}'),
              ),
              const SizedBox(height: 12),
              const Text('Enviar por'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('WhatsApp'),
                    selected: _channel == 'whatsapp',
                    onSelected: (_) => setState(() => _channel = 'whatsapp'),
                  ),
                  ChoiceChip(
                    label: const Text('SMS'),
                    selected: _channel == 'sms',
                    onSelected: (_) => setState(() => _channel = 'sms'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notas para la portería'),
                maxLength: 120,
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Crear y enviar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../session/presentation/session_controller.dart';
import '../domain/incident.dart';
import 'incidents_controller.dart';

class ReportIncidentScreen extends ConsumerStatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  ConsumerState<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends ConsumerState<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String? _incidentTypeId;
  IncidentPriority _priority = IncidentPriority.medium;
  final List<File> _photos = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked == null) return;
    setState(() => _photos.add(File(picked.path)));
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    setState(() => _photos.add(File(picked.path)));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final membership = ref.read(selectedMembershipProvider).value;
    if (membership == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(incidentsRepositoryProvider).reportIncident(
            residentialId: membership.residentialId,
            unitId: membership.unitId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            incidentTypeId: _incidentTypeId,
            location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
            priority: _priority,
            photos: _photos,
          );
      ref.invalidate(incidentsListProvider(membership.residentialId));
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incidencia reportada')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo reportar. Intenta de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final membership = ref.watch(selectedMembershipProvider).value;
    final incidentTypesAsync = membership == null
        ? const AsyncValue<List<IncidentType>>.data([])
        : ref.watch(incidentTypesProvider(membership.residentialId));

    return Scaffold(
      appBar: AppBar(title: const Text('Reportar incidencia')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _incidentTypeId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: (incidentTypesAsync.value ?? [])
                    .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                    .toList(),
                onChanged: (v) => setState(() => _incidentTypeId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<IncidentPriority>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Prioridad'),
                items: IncidentPriority.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(priorityLabel(p))))
                    .toList(),
                onChanged: (v) => setState(() => _priority = v ?? IncidentPriority.medium),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Ubicación (opcional)', hintText: 'Ej. Torre A, Piso 2'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final photo in _photos)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(photo, width: 72, height: 72, fit: BoxFit.cover),
                    ),
                  OutlinedButton.icon(
                    onPressed: _addPhoto,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Cámara'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galería'),
                  ),
                ],
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
                    : const Text('Enviar reporte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

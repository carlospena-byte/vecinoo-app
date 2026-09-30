import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_phone_field.dart';
import '../../../core/widgets/gates_select_field.dart';
import '../../../core/widgets/gates_sheet.dart';
import '../../../core/widgets/gates_switch_row.dart';
import '../../../core/widgets/gates_text_area.dart';
import '../../../core/widgets/gates_text_field.dart';
import '../../../core/widgets/gates_time_picker.dart';
import '../../../core/widgets/gates_toast.dart';
import '../../../core/widgets/gates_upload_card.dart';
import '../../home/home_shell.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/visit.dart';
import 'frequent_visit_formatters.dart';
import 'schedule_block_card.dart';
import 'visits_controller.dart';

const _notesMaxLength = 120;
const _maxDocumentBytes = 10 * 1024 * 1024;

/// Acceso frecuente flow — Figma "09 · Visitas / Acceso frecuente"
/// (node 116:185). Two steps in one screen: R01 "Datos de la visita" (name,
/// type, phone, ID document, vehicle) and R02/R03 "Días y horario" (frequency,
/// schedule or custom blocks, notes, arrival alert). The back arrow steps back
/// to R01 before leaving the flow.
class CreateFrequentVisitScreen extends ConsumerStatefulWidget {
  const CreateFrequentVisitScreen({super.key, this.editing});

  /// When set, the form is prefilled from this frequent visit and saving
  /// updates it instead of creating a new one.
  final Visit? editing;

  @override
  ConsumerState<CreateFrequentVisitScreen> createState() =>
      _CreateFrequentVisitScreenState();
}

class _CreateFrequentVisitScreenState
    extends ConsumerState<CreateFrequentVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _plateController = TextEditingController();
  final _notesController = TextEditingController();

  int _step = 0;

  // Step 1
  VisitorRole _role = VisitorRole.familiar;
  GatesCountryCode _country = gatesCountryCodes.first;
  File? _document;
  bool _documentMissing = false;
  String? _documentError;
  bool _hasVehicle = false;

  // Step 2
  Recurrence _recurrence = Recurrence.monFri;
  ScheduleType _scheduleType = ScheduleType.allDay;
  TimeOfDay _scheduleStart = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _scheduleEnd = const TimeOfDay(hour: 22, minute: 0);
  final List<ScheduleBlockDraft> _blocks = [];
  bool _notifyOnArrival = true;

  bool _isSubmitting = false;

  bool get _isEditing => widget.editing != null;

  /// The visit already has an ID photo on file; a new one is only needed if
  /// the resident removes it to replace it.
  late bool _keepsExistingDocument = widget.editing?.idPhotoPath != null;

  @override
  void initState() {
    super.initState();
    final visit = widget.editing;
    if (visit == null) return;
    _nameController.text = visit.name ?? '';
    _role = visit.visitorRole ?? VisitorRole.familiar;
    _splitPhone(visit.phone);
    _hasVehicle = visit.hasVehicle;
    _plateController.text = visit.plate ?? '';
    _recurrence = visit.recurrence ?? Recurrence.monFri;
    _scheduleType = visit.scheduleType ?? ScheduleType.allDay;
    _scheduleStart = visit.scheduleStart ?? _scheduleStart;
    _scheduleEnd = visit.scheduleEnd ?? _scheduleEnd;
    if (_recurrence == Recurrence.custom) {
      final blocks = visit.scheduleBlocks;
      if (blocks != null && blocks.isNotEmpty) {
        for (final b in blocks) {
          _blocks.add(
            ScheduleBlockDraft(days: {...b.days}, start: b.start, end: b.end),
          );
        }
      } else {
        // Saved before blocks existed: rebuild a single block.
        _blocks.add(
          ScheduleBlockDraft(
            days: {...?visit.recurrenceDays},
            start: _scheduleStart,
            end: _scheduleEnd,
          ),
        );
      }
    }
    _notifyOnArrival = visit.notifyOnArrival;
    _notesController.text = visit.notes ?? '';
  }

  /// "+50499999999" -> country chip + local number.
  void _splitPhone(String? phone) {
    if (phone == null || phone.isEmpty) return;
    final matches =
        gatesCountryCodes.where((c) => phone.startsWith(c.dialCode)).toList()
          ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
    if (matches.isEmpty) {
      _phoneController.text = phone;
      return;
    }
    _country = matches.first;
    _phoneController.text = phone.substring(_country.dialCode.length);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _plateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _documentLabel() {
    final file = _document;
    if (file == null) return _keepsExistingDocument ? 'Documento actual' : null;
    final name = file.path.split('/').last;
    final mb = file.lengthSync() / (1024 * 1024);
    return '$name · ${mb.toStringAsFixed(1)} MB';
  }

  Future<void> _pickDocument() async {
    final source = await showGatesSheet<ImageSource>(
      context,
      (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: GatesSpacing.space24)
            .copyWith(bottom: GatesSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GatesSheetHeader(title: 'Documento de identidad'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('Tomar foto', style: GatesTypography.body),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('Elegir de la galería', style: GatesTypography.body),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
    );
    if (picked == null || !mounted) return;
    final file = File(picked.path);
    setState(() {
      if (file.lengthSync() > _maxDocumentBytes) {
        _document = null;
        _documentError = 'La foto supera los 10 MB. Elige una más ligera.';
      } else {
        _document = file;
        _keepsExistingDocument = false;
        _documentError = null;
        _documentMissing = false;
      }
    });
  }

  void _removeDocument() => setState(() {
    _document = null;
    _documentError = null;
    _keepsExistingDocument = false;
  });

  void _onFrequencyChanged(Recurrence value) {
    setState(() {
      _recurrence = value;
      if (value == Recurrence.custom && _blocks.isEmpty) {
        _blocks.add(
          ScheduleBlockDraft(days: {'mon', 'tue', 'wed', 'thu', 'fri'}),
        );
      }
    });
  }

  Set<String> _daysTakenByOthers(ScheduleBlockDraft block) => {
    for (final other in _blocks)
      if (!identical(other, block)) ...other.days,
  };

  Future<void> _pickScheduleTime({required bool isStart}) async {
    final picked = await showGatesTimePicker(
      context,
      initialTime: isStart ? _scheduleStart : _scheduleEnd,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _scheduleStart = picked;
      } else {
        _scheduleEnd = picked;
      }
    });
  }

  void _warn(String message) => showGatesToast(
    context,
    type: GatesToastType.warning,
    title: 'Falta un dato',
    message: message,
  );

  bool _isBefore(TimeOfDay a, TimeOfDay b) =>
      a.hour * 60 + a.minute < b.hour * 60 + b.minute;

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_document == null && !_keepsExistingDocument) {
      setState(() => _documentMissing = true);
      return;
    }
    setState(() => _step = 1);
  }

  Future<void> _submit() async {
    if (_recurrence == Recurrence.custom) {
      for (final block in _blocks) {
        if (block.days.isEmpty) {
          _warn('Selecciona al menos un día en cada bloque de horario.');
          return;
        }
        if (!_isBefore(block.start, block.end)) {
          _warn('La hora de inicio debe ser anterior a la hora final.');
          return;
        }
      }
    } else if (_scheduleType == ScheduleType.custom &&
        !_isBefore(_scheduleStart, _scheduleEnd)) {
      _warn('La hora de inicio debe ser anterior a la hora final.');
      return;
    }
    final membership = ref.read(selectedMembershipProvider).value;
    final document = _document;
    if (membership == null) return;
    if (document == null && !_keepsExistingDocument) return;

    setState(() => _isSubmitting = true);
    final repository = ref.read(visitsRepositoryProvider);
    try {
      final photoPath = document == null
          ? null
          : await repository.uploadVisitorDocument(
              residentialId: membership.residentialId,
              file: document,
            );
      final digits = _phoneController.text.trim();
      final phone = digits.isEmpty
          ? null
          : '${_country.dialCode}${digits.replaceAll(RegExp(r'[^0-9]'), '')}';
      final plate = _plateController.text.trim().toUpperCase();
      final blocks = _recurrence == Recurrence.custom
          ? [for (final b in _blocks) b.toBlock()]
          : null;
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();
      final editing = widget.editing;
      if (editing != null) {
        await repository.updateFrequentVisit(
          visitId: editing.id,
          name: _nameController.text.trim(),
          phone: phone,
          visitorRole: _role,
          idPhotoPath: photoPath,
          hasVehicle: _hasVehicle,
          plate: plate,
          recurrence: _recurrence,
          scheduleType: _scheduleType,
          scheduleStart: _scheduleStart,
          scheduleEnd: _scheduleEnd,
          scheduleBlocks: blocks,
          notifyOnArrival: _notifyOnArrival,
          notes: notes,
        );
        if (!mounted) return;
        showGatesToast(
          context,
          type: GatesToastType.success,
          title: 'Acceso actualizado',
        );
        context.pop();
        return;
      }
      await repository.createFrequentVisit(
        residentialId: membership.residentialId,
        unitId: membership.unitId,
        name: _nameController.text.trim(),
        phone: phone,
        visitorRole: _role,
        idPhotoPath: photoPath!,
        hasVehicle: _hasVehicle,
        plate: plate,
        recurrence: _recurrence,
        scheduleType: _scheduleType,
        scheduleStart: _scheduleStart,
        scheduleEnd: _scheduleEnd,
        scheduleBlocks: blocks,
        notifyOnArrival: _notifyOnArrival,
        notes: notes,
      );
      if (!mounted) return;
      showGatesToast(
        context,
        type: GatesToastType.success,
        title: 'Acceso frecuente autorizado',
      );
      context.go('/', extra: const HomeTabRequest(HomeShell.visitsTab));
    } catch (_) {
      if (mounted) {
        showGatesToast(
          context,
          type: GatesToastType.error,
          title: _isEditing
              ? 'No pudimos guardar los cambios'
              : 'No pudimos autorizar el acceso',
          message: 'Intenta de nuevo.',
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFirstStep = _step == 0;
    return PopScope(
      canPop: isFirstStep || _isSubmitting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step = 0);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(isFirstStep ? 'Acceso frecuente' : 'Días y horario'),
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                GatesSpacing.space24,
                GatesSpacing.space8,
                GatesSpacing.space24,
                GatesSpacing.space24,
              ),
              children: [
                Text(
                  isFirstStep
                      ? '1 de 2 · Datos de la visita'
                      : '2 de 2 · Permisos de acceso',
                  style: GatesTypography.caption,
                ),
                const SizedBox(height: GatesSpacing.space16),
                if (isFirstStep) ..._dataStep() else ..._scheduleStep(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(GatesSpacing.space24),
          child: GatesButton(
            label: isFirstStep
                ? 'Continuar'
                : (_isEditing ? 'Guardar cambios' : 'Autorizar acceso'),
            loading: _isSubmitting,
            onPressed: _isSubmitting
                ? null
                : (isFirstStep ? _continue : _submit),
          ),
        ),
      ),
    );
  }

  List<Widget> _dataStep() {
    final uploadState = _isSubmitting
        ? GatesUploadState.uploading
        : _documentError != null || _documentMissing
        ? GatesUploadState.error
        : (_document != null || _keepsExistingDocument)
        ? GatesUploadState.ready
        : GatesUploadState.empty;
    return [
      GatesTextField(
        controller: _nameController,
        label: 'Nombre de la visita *',
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        validator: (v) => (v == null || v.trim().isEmpty)
            ? 'Escribe el nombre de la visita.'
            : null,
      ),
      const SizedBox(height: GatesSpacing.space16),
      GatesSelectField<VisitorRole>(
        label: 'Tipo',
        value: _role,
        options: {for (final r in VisitorRole.values) r: visitorRoleLabel(r)},
        onChanged: (r) => setState(() => _role = r),
      ),
      const SizedBox(height: GatesSpacing.space16),
      GatesPhoneField(
        controller: _phoneController,
        country: _country,
        onCountryChanged: (c) => setState(() => _country = c),
        validator: (v) {
          final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
          if (digits.isEmpty) return null;
          return digits.length < 7 || digits.length > 12
              ? 'Escribe un teléfono válido.'
              : null;
        },
      ),
      const SizedBox(height: GatesSpacing.space16),
      GatesUploadCard(
        title: 'Documento de identidad *',
        emptyDescription: 'Adjunta una foto legible del documento.',
        state: uploadState,
        fileLabel: _documentLabel(),
        errorDescription:
            _documentError ?? 'Adjunta una foto del documento para continuar.',
        onPick: _pickDocument,
        onRemove: _removeDocument,
      ),
      const SizedBox(height: GatesSpacing.space16),
      GatesSwitchRow(
        label: 'Ingresará en vehículo',
        description: 'Activa para ingresar la placa',
        value: _hasVehicle,
        onChanged: (v) => setState(() => _hasVehicle = v),
      ),
      const SizedBox(height: GatesSpacing.space16),
      GatesTextField(
        controller: _plateController,
        label: 'Placa del vehículo',
        hintText: 'Ingresa la placa',
        enabled: _hasVehicle,
        textCapitalization: TextCapitalization.characters,
        validator: (v) => _hasVehicle && (v == null || v.trim().isEmpty)
            ? 'Escribe la placa del vehículo.'
            : null,
      ),
    ];
  }

  List<Widget> _scheduleStep() {
    final isCustom = _recurrence == Recurrence.custom;
    return [
      GatesSelectField<Recurrence>(
        label: 'Frecuencia',
        value: _recurrence,
        options: {for (final r in Recurrence.values) r: recurrenceLabel(r)},
        onChanged: _onFrequencyChanged,
      ),
      const SizedBox(height: GatesSpacing.space12),
      if (isCustom) ...[
        Text(
          'Agrupa los días que comparten el mismo horario.',
          style: GatesTypography.caption.copyWith(fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: GatesSpacing.space12),
        for (var i = 0; i < _blocks.length; i++) ...[
          ScheduleBlockCard(
            index: i,
            draft: _blocks[i],
            takenDays: _daysTakenByOthers(_blocks[i]),
            onChanged: () => setState(() {}),
            onRemove: _blocks.length > 1
                ? () => setState(() => _blocks.removeAt(i))
                : null,
          ),
          const SizedBox(height: GatesSpacing.space12),
        ],
        _AddBlockButton(
          // Every day already belongs to a block: nothing left to add.
          onPressed:
              _blocks.expand((b) => b.days).toSet().length >= weekdayKeys.length
              ? null
              : () => setState(() => _blocks.add(ScheduleBlockDraft())),
        ),
      ] else ...[
        GatesSelectField<ScheduleType>(
          label: 'Horario',
          value: _scheduleType,
          options: const {
            ScheduleType.allDay: 'Todo el día',
            ScheduleType.custom: 'Personalizado',
          },
          onChanged: (t) => setState(() => _scheduleType = t),
        ),
        if (_scheduleType == ScheduleType.custom) ...[
          const SizedBox(height: GatesSpacing.space12),
          Row(
            children: [
              Expanded(
                child: GatesTimeField(
                  label: 'Desde',
                  value: formatClockField(_scheduleStart),
                  onTap: () => _pickScheduleTime(isStart: true),
                ),
              ),
              const SizedBox(width: GatesSpacing.space8),
              Expanded(
                child: GatesTimeField(
                  label: 'Hasta',
                  value: formatClockField(_scheduleEnd),
                  onTap: () => _pickScheduleTime(isStart: false),
                ),
              ),
            ],
          ),
        ],
      ],
      const SizedBox(height: GatesSpacing.space16),
      GatesTextArea(controller: _notesController, maxLength: _notesMaxLength),
      const SizedBox(height: GatesSpacing.space16),
      GatesSwitchRow(
        label: 'Avisarme al llegar',
        description: 'Notificaciones de mis visitas',
        value: _notifyOnArrival,
        onChanged: (v) => setState(() => _notifyOnArrival = v),
      ),
    ];
  }
}

/// Figma "Agregar bloque de horario": a white 48px pill.
class _AddBlockButton extends StatelessWidget {
  const _AddBlockButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: GatesColors.bgSurface,
          foregroundColor: GatesColors.textBrand,
          disabledForegroundColor: GatesColors.textSecondary,
          shape: const StadiumBorder(),
          textStyle: GatesTypography.label,
        ),
        child: const Text('+ Agregar bloque'),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_select_field.dart';
import '../../../core/widgets/gates_text_field.dart';
import '../../../core/widgets/gates_toast.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/incident.dart';
import 'incident_edit_args.dart';
import 'incident_rich_editor.dart';
import '../../../core/widgets/gates_sheet.dart';
import 'incidents_controller.dart';

const _maxPhotos = 10;

enum _Phase { form, sending, photoError, sent }

enum _PhotoStatus { ready, uploading, done, error }

class _Photo {
  _Photo(File this.file) : status = _PhotoStatus.ready;

  /// A photo already stored on the server (edit mode).
  _Photo.existing(IncidentAttachment this.attachment)
    : url = attachment.url,
      status = _PhotoStatus.done;

  File? file;
  String? url;
  IncidentAttachment? attachment;
  _PhotoStatus status;
}

/// "15 · Incidencias / Crear reporte" — Figma nodes I01/I03 (form), I04
/// (photo source sheet), I06 (photo upload error), I07 (sending) and I08
/// (sent). One screen drives all of them through [_Phase].
class ReportIncidentScreen extends ConsumerStatefulWidget {
  const ReportIncidentScreen({super.key, this.editing});

  /// When set, the form is prefilled from this incident and saving updates
  /// it instead of creating a new one (Figma I14).
  final IncidentEditArgs? editing;

  @override
  ConsumerState<ReportIncidentScreen> createState() =>
      _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends ConsumerState<ReportIncidentScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = RichTextController();

  _Phase _phase = _Phase.form;
  String? _incidentTypeId;
  final List<_Photo> _photos = [];

  /// Set once the row exists, so retrying photo uploads never creates a
  /// second incident.
  String? _incidentId;

  /// Server photos the user removed while editing; deleted on save.
  final List<IncidentAttachment> _removedAttachments = [];

  bool get _isEditing => widget.editing != null;

  /// Snapshot shown on the confirmation screen.
  String _sentTitle = '';
  String? _sentCategory;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      final incident = editing.incident;
      _incidentId = incident.id;
      _incidentTypeId = incident.incidentTypeId;
      _titleController.text = incident.title;
      _descriptionController.loadHtml(incident.description);
      _photos.addAll(editing.attachments.map(_Photo.existing));
    }
    _baseline = _signature();
    _titleController.addListener(_syncDirty);
    _descriptionController.addListener(_syncDirty);
  }

  bool _dirty = false;

  /// Only rebuilds when the dirty flag flips, so typing stays cheap.
  void _syncDirty() {
    final dirty = _isDirty;
    if (dirty != _dirty && mounted) setState(() => _dirty = dirty);
  }

  late final String _baseline;

  String _signature() =>
      '${_titleController.text}|${_descriptionController.text}|'
      '$_incidentTypeId|${_photos.length}|${_removedAttachments.length}';

  bool get _isDirty => _signature() != _baseline;

  /// Leaving with unsaved edits asks for confirmation (edit mode only).
  bool get _confirmsExit => _isEditing && _phase == _Phase.form && _isDirty;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _hasErrors => _photos.any((p) => p.status == _PhotoStatus.error);

  int get _uploadedCount =>
      _photos.where((p) => p.status == _PhotoStatus.done).length;

  Future<void> _pickPhotos() async {
    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) return;
    final source = await _showPhotoSourceSheet();
    if (source == null || !mounted) return;
    try {
      final picker = ImagePicker();
      List<XFile> picked;
      if (source == ImageSource.camera) {
        final shot = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 70,
        );
        picked = shot == null ? [] : [shot];
      } else {
        picked = await picker.pickMultiImage(imageQuality: 70);
      }
      if (picked.isEmpty || !mounted) return;
      if (picked.length > remaining) {
        showGatesToast(
          context,
          type: GatesToastType.info,
          title: 'Máximo $_maxPhotos fotografías',
          message: 'Agregamos las primeras $remaining.',
        );
        picked = picked.take(remaining).toList();
      }
      setState(() => _photos.addAll(picked.map((x) => _Photo(File(x.path)))));
      // After the report already exists, new photos go up right away.
      if (_incidentId != null) await _uploadPending();
    } catch (_) {
      if (!mounted) return;
      showGatesToast(
        context,
        type: GatesToastType.error,
        title: 'No pudimos abrir las fotografías',
        message: 'Revisa los permisos e intenta de nuevo.',
      );
    }
  }

  Future<ImageSource?> _showPhotoSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      builder: (sheetContext) => _PhotoSourceSheet(
        onPick: (source) => Navigator.of(sheetContext).pop(source),
        onCancel: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }

  Future<void> _submit() async {
    final membership = ref.read(selectedMembershipProvider).value;
    if (membership == null) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final types =
        ref.read(incidentTypesProvider(membership.residentialId)).value ?? [];
    _sentTitle = title;
    _sentCategory = types
        .where((t) => t.id == _incidentTypeId)
        .map((t) => t.name)
        .firstOrNull;

    setState(() => _phase = _Phase.sending);
    if (_isEditing) {
      try {
        final repository = ref.read(incidentsRepositoryProvider);
        await repository.updateIncident(
          incidentId: _incidentId!,
          title: title,
          description: _descriptionController.toHtml(),
          incidentTypeId: _incidentTypeId,
        );
        for (final attachment in _removedAttachments.toList()) {
          await repository.deleteAttachment(attachment);
          _removedAttachments.remove(attachment);
        }
        ref.invalidate(incidentsListProvider(membership.residentialId));
      } catch (_) {
        if (!mounted) return;
        // Keep every change so the user can retry.
        setState(() => _phase = _Phase.form);
        showGatesToast(
          context,
          type: GatesToastType.error,
          title: 'No pudimos guardar los cambios',
          message: 'Tus cambios se conservaron. Intenta de nuevo.',
        );
        return;
      }
      await _uploadPending();
      return;
    }
    try {
      _incidentId ??= await ref
          .read(incidentsRepositoryProvider)
          .createIncident(
            residentialId: membership.residentialId,
            unitId: membership.unitId,
            title: title,
            description: _descriptionController.toHtml(),
            incidentTypeId: _incidentTypeId,
          );
      ref.invalidate(incidentsListProvider(membership.residentialId));
    } catch (_) {
      if (!mounted) return;
      setState(() => _phase = _Phase.form);
      showGatesToast(
        context,
        type: GatesToastType.error,
        title: 'No pudimos enviar el reporte',
        message: 'Tus datos se conservaron. Intenta de nuevo.',
      );
      return;
    }
    await _uploadPending();
  }

  /// Uploads every photo that is waiting (or failed before), one at a time,
  /// then lands on the error screen if any are left or on the confirmation.
  Future<void> _uploadPending() async {
    final membership = ref.read(selectedMembershipProvider).value;
    final incidentId = _incidentId;
    if (membership == null || incidentId == null) return;

    setState(() => _phase = _Phase.sending);
    final repository = ref.read(incidentsRepositoryProvider);
    for (final photo in _photos.toList()) {
      if (photo.status != _PhotoStatus.ready &&
          photo.status != _PhotoStatus.error) {
        continue;
      }
      if (!mounted) return;
      setState(() => photo.status = _PhotoStatus.uploading);
      try {
        await repository.uploadPhoto(
          residentialId: membership.residentialId,
          incidentId: incidentId,
          photo: photo.file!,
        );
        photo.status = _PhotoStatus.done;
      } catch (_) {
        photo.status = _PhotoStatus.error;
      }
      if (mounted) setState(() {});
    }
    if (!mounted) return;
    if (_hasErrors) {
      setState(() => _phase = _Phase.photoError);
    } else {
      _finish();
    }
  }

  /// Edit mode returns to the detail once the server confirmed everything;
  /// a new report shows the confirmation screen.
  void _finish() {
    if (_isEditing) {
      context.pop();
      showGatesToast(
        context,
        type: GatesToastType.success,
        title: 'Cambios guardados',
      );
    } else {
      setState(() => _phase = _Phase.sent);
    }
  }

  void _removePhoto(_Photo photo) {
    setState(() {
      _photos.remove(photo);
      final attachment = photo.attachment;
      if (attachment != null) _removedAttachments.add(attachment);
    });
  }

  Future<void> _confirmDiscard() async {
    final discard = await showGatesSheet<bool>(
      context,
      (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: GatesSpacing.space24)
            .copyWith(bottom: GatesSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GatesSheetHeader(title: '¿Descartar cambios?'),
            const SizedBox(height: GatesSpacing.space8),
            Text(
              'Si sales ahora, los cambios que hiciste no se guardarán.',
              style: GatesTypography.body,
            ),
            const SizedBox(height: GatesSpacing.space24),
            GatesButton(
              label: 'Descartar cambios',
              style: GatesButtonStyle.destructive,
              onPressed: () => Navigator.of(sheetContext).pop(true),
            ),
            const SizedBox(height: GatesSpacing.space8),
            GatesButton(
              label: 'Seguir editando',
              style: GatesButtonStyle.secondary,
              onPressed: () => Navigator.of(sheetContext).pop(false),
            ),
          ],
        ),
      ),
    );
    if (discard == true && mounted) context.pop();
  }

  void _goHome() => context.go('/');

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _phase != _Phase.sending && !_confirmsExit,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _confirmsExit) _confirmDiscard();
      },
      child: switch (_phase) {
        _Phase.form => _buildForm(context),
        _Phase.sending => _buildSending(context),
        _Phase.photoError => _buildPhotoError(context),
        _Phase.sent => _buildSent(context),
      },
    );
  }

  // ---------------------------------------------------------------- form

  Widget _buildForm(BuildContext context) {
    final membership = ref.watch(selectedMembershipProvider).value;
    final types = membership == null
        ? const <IncidentType>[]
        : ref.watch(incidentTypesProvider(membership.residentialId)).value ??
              const <IncidentType>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          _isEditing ? 'Editar incidencia' : 'Reportar incidencia',
          style: _appBarTitle,
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            GatesSpacing.space24,
            0,
            GatesSpacing.space24,
            GatesSpacing.space24,
          ),
          children: [
            Text(
              'Cuéntanos qué ocurrió. Un administrador dará seguimiento.',
              style: GatesTypography.labelSecondary,
            ),
            const SizedBox(height: GatesSpacing.space16),
            GatesSelectField<String>(
              label: 'Categoría (opcional)',
              placeholder: 'Seleccionar categoría',
              value: _incidentTypeId ?? '',
              options: {for (final t in types) t.id: t.name},
              onChanged: (id) => setState(() => _incidentTypeId = id),
            ),
            const SizedBox(height: GatesSpacing.space16),
            GatesTextField(
              controller: _titleController,
              label: 'Título *',
              hintText: '¿Qué problema quieres reportar?',
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: GatesSpacing.space16),
            IncidentRichEditor(controller: _descriptionController),
            const SizedBox(height: GatesSpacing.space16),
            _PhotosSection(
              photos: _photos,
              onAdd: _pickPhotos,
              onRemove: _removePhoto,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _FixedAction(
        child: ListenableBuilder(
          listenable: _titleController,
          builder: (context, _) => GatesButton(
            label: _isEditing ? 'Guardar cambios' : 'Reportar incidencia',
            onPressed: _titleController.text.trim().isEmpty ? null : _submit,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- sending

  Widget _buildSending(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text('Reportar incidencia', style: _appBarTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(GatesSpacing.space24).copyWith(top: 0),
        children: [
          Text(
            _isEditing
                ? 'Estamos guardando tus cambios'
                : 'Estamos enviando tu reporte',
            style: GatesTypography.headingMedium,
          ),
          const SizedBox(height: GatesSpacing.space16),
          Text(
            'Espera un momento mientras guardamos los datos y las fotografías.',
            style: GatesTypography.labelSecondary,
          ),
          const SizedBox(height: GatesSpacing.space16),
          _PhotosSection(photos: _photos, showAdd: false),
        ],
      ),
      bottomNavigationBar: const _FixedAction(
        child: GatesButton(label: 'Enviando…', onPressed: null),
      ),
    );
  }

  // --------------------------------------------------------- photo error

  Widget _buildPhotoError(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text('Fotografías', style: _appBarTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(GatesSpacing.space24).copyWith(top: 0),
        children: [
          if (_hasErrors) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(GatesSpacing.space16),
              decoration: BoxDecoration(
                color: GatesColors.statusErrorBg,
                borderRadius: BorderRadius.circular(GatesRadius.radius16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Una foto no se pudo subir',
                    style: GatesTypography.label.copyWith(
                      color: GatesColors.statusError,
                    ),
                  ),
                  const SizedBox(height: GatesSpacing.space8),
                  Text(
                    'Reintenta la carga o elimina esa foto para continuar.',
                    style: GatesTypography.labelSecondary.copyWith(
                      color: GatesColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: GatesSpacing.space16),
          ],
          _PhotosSection(
            photos: _photos,
            onAdd: _pickPhotos,
            onRemove: _removePhoto,
            onRetry: (_) => _uploadPending(),
            removableStatuses: const {_PhotoStatus.error},
          ),
          if (_hasErrors) ...[
            const SizedBox(height: GatesSpacing.space16),
            GatesButton(
              label: 'Reintentar fotografía',
              style: GatesButtonStyle.secondary,
              onPressed: _uploadPending,
            ),
          ],
        ],
      ),
      bottomNavigationBar: _FixedAction(
        child: GatesButton(
          label: 'Listo',
          onPressed: _hasErrors ? null : _finish,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- sent

  Widget _buildSent(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: BackButton(onPressed: _goHome),
          title: Text('Incidencia enviada', style: _appBarTitle),
        ),
        body: ListView(
          padding: const EdgeInsets.all(GatesSpacing.space24).copyWith(top: 0),
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: GatesColors.statusSuccessBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 24,
                    color: GatesColors.textBrand,
                  ),
                ),
                const SizedBox(width: GatesSpacing.space16),
                Expanded(
                  child: Text(
                    'Tu reporte fue enviado',
                    style: GatesTypography.headingMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: GatesSpacing.space16),
            Text(
              'Un administrador dará seguimiento a la incidencia.',
              style: GatesTypography.body.copyWith(
                color: GatesColors.textSecondary,
              ),
            ),
            const SizedBox(height: GatesSpacing.space16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: GatesColors.bgSurface,
                borderRadius: BorderRadius.circular(GatesRadius.radius16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_sentTitle, style: GatesTypography.headingSmall),
                  if (_sentCategory != null) ...[
                    const SizedBox(height: GatesSpacing.space12),
                    Text(_sentCategory!, style: GatesTypography.labelSecondary),
                  ],
                  const SizedBox(height: GatesSpacing.space12),
                  Text(
                    'Reporte recibido',
                    style: GatesTypography.label.copyWith(
                      color: GatesColors.statusSuccess,
                    ),
                  ),
                  const SizedBox(height: GatesSpacing.space12),
                  Row(
                    children: [
                      Text(
                        'Fotografías',
                        style: GatesTypography.labelSecondary,
                      ),
                      const SizedBox(width: GatesSpacing.space12),
                      Text(
                        '$_uploadedCount / $_maxPhotos',
                        style: GatesTypography.labelSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _FixedAction(
          child: GatesButton(label: 'Volver al inicio', onPressed: _goHome),
        ),
      ),
    );
  }
}

/// AppBar title in the Figma AppBar: Heading/Small (20 / semibold).
final _appBarTitle = GatesTypography.headingSmall;

/// Figma "Acción fija": white bar pinned above the system inset holding the
/// primary button.
class _FixedAction extends StatelessWidget {
  const _FixedAction({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GatesColors.bgSurface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: GatesSpacing.space24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            GatesSpacing.space24,
            GatesSpacing.space12,
            GatesSpacing.space24,
            0,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// "Fotografías" block: header with `n / 10`, the thumbnails and the
/// "Agregar fotografías" card.
class _PhotosSection extends StatelessWidget {
  const _PhotosSection({
    required this.photos,
    this.onAdd,
    this.onRemove,
    this.onRetry,
    this.showAdd = true,
    this.removableStatuses,
  });

  final List<_Photo> photos;
  final VoidCallback? onAdd;
  final ValueChanged<_Photo>? onRemove;
  final ValueChanged<_Photo>? onRetry;
  final bool showAdd;

  /// When set, only photos in these statuses show the delete button.
  final Set<_PhotoStatus>? removableStatuses;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fotografías (opcional)', style: GatesTypography.label),
            Text(
              '${photos.length} / $_maxPhotos',
              style: GatesTypography.caption.copyWith(height: 16 / 12),
            ),
          ],
        ),
        const SizedBox(height: GatesSpacing.space8),
        if (photos.isNotEmpty)
          Wrap(
            spacing: GatesSpacing.space12,
            runSpacing: GatesSpacing.space12,
            children: [
              for (final photo in photos)
                _PhotoTile(
                  photo: photo,
                  canRemove:
                      onRemove != null &&
                      (removableStatuses?.contains(photo.status) ?? true),
                  onRemove: () => onRemove?.call(photo),
                  onRetry: () => onRetry?.call(photo),
                ),
            ],
          ),
        if (showAdd && photos.length < _maxPhotos) ...[
          if (photos.isNotEmpty) const SizedBox(height: GatesSpacing.space12),
          _AddPhotosCard(
            title: photos.isEmpty ? 'Agregar fotografías' : 'Agregar más fotos',
            onTap: onAdd,
          ),
        ],
      ],
    );
  }
}

class _AddPhotosCard extends StatelessWidget {
  const _AddPhotosCard({required this.title, required this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GatesColors.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GatesRadius.radius16),
        side: const BorderSide(color: GatesColors.borderDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(GatesSpacing.space16),
          child: Row(
            children: [
              const Icon(
                Icons.photo_camera_outlined,
                size: 24,
                color: GatesColors.textPrimary,
              ),
              const SizedBox(width: GatesSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GatesTypography.label.copyWith(
                        color: GatesColors.textBrand,
                      ),
                    ),
                    const SizedBox(height: GatesSpacing.space4),
                    Text(
                      'Hasta $_maxPhotos fotografías',
                      style: GatesTypography.caption.copyWith(height: 16 / 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Figma "Incidencias / Fotografía" (node `461:974`): 104×100 thumbnail with
/// a delete button and, while uploading or after a failure, a status pill.
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.canRemove,
    required this.onRemove,
    required this.onRetry,
  });

  final _Photo photo;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final status = photo.status;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 104,
        height: 100,
        child: Stack(
          fit: StackFit.expand,
          children: [
            photo.file != null
                ? Image.file(photo.file!, fit: BoxFit.cover)
                : Image.network(photo.url!, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  canRemove && status != _PhotoStatus.uploading
                      ? Semantics(
                          button: true,
                          label: 'Eliminar fotografía',
                          child: GestureDetector(
                            onTap: onRemove,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: GatesColors.bgSurface,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 20,
                                color: GatesColors.textPrimary,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(height: 28),
                  if (status == _PhotoStatus.uploading)
                    const _StatusPill(
                      label: 'Subiendo…',
                      background: GatesColors.bgSurface,
                      foreground: GatesColors.textBrand,
                    ),
                  if (status == _PhotoStatus.error)
                    GestureDetector(
                      onTap: onRetry,
                      child: const _StatusPill(
                        label: 'Reintentar',
                        background: GatesColors.statusErrorBg,
                        foreground: GatesColors.statusError,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GatesSpacing.space4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(GatesRadius.radius8),
      ),
      child: Text(
        label,
        style: GatesTypography.caption.copyWith(
          color: foreground,
          height: 16 / 12,
        ),
      ),
    );
  }
}

/// Figma "Fotografías / Bottom sheet" (node `473:2395`): a floating white
/// sheet with the two sources, plus a separate "Cancelar" pill below it.
class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet({required this.onPick, required this.onCancel});

  final ValueChanged<ImageSource> onPick;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(GatesSpacing.space24),
              decoration: BoxDecoration(
                color: GatesColors.bgSurface,
                borderRadius: BorderRadius.circular(GatesRadius.radius24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Agregar fotografías',
                          style: GatesTypography.headingSmall,
                        ),
                      ),
                      InkResponse(
                        onTap: onCancel,
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: GatesColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: GatesSpacing.space16),
                  Text(
                    'Elige cómo quieres agregar tus fotos.',
                    style: GatesTypography.body.copyWith(
                      color: GatesColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: GatesSpacing.space16),
                  _SheetAction(
                    label: 'Tomar foto',
                    onTap: () => onPick(ImageSource.camera),
                  ),
                  const SizedBox(height: GatesSpacing.space8),
                  _SheetAction(
                    label: 'Elegir de la galería',
                    onTap: () => onPick(ImageSource.gallery),
                  ),
                ],
              ),
            ),
            const SizedBox(height: GatesSpacing.space12),
            _SheetAction(
              label: 'Cancelar',
              onTap: onCancel,
              background: GatesColors.bgSurface,
              height: 52,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.label,
    required this.onTap,
    this.background = GatesColors.bgSubtle,
    this.height = 56,
  });

  final String label;
  final VoidCallback onTap;
  final Color background;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Center(
            child: Text(
              label,
              style: GatesTypography.label.copyWith(
                color: GatesColors.textBrand,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import 'photo_picker.dart';
import 'report_incident_controller.dart';

/// "Fotografías" block: header with `n / 10`, the thumbnails and the
/// "Agregar fotografías" card.
class PhotosSection extends StatelessWidget {
  const PhotosSection({
    super.key,
    required this.photos,
    this.onAdd,
    this.onRemove,
    this.onRetry,
    this.showAdd = true,
    this.removableStatuses,
  });

  final List<ReportPhoto> photos;
  final VoidCallback? onAdd;
  final ValueChanged<ReportPhoto>? onRemove;
  final ValueChanged<ReportPhoto>? onRetry;
  final bool showAdd;

  /// When set, only photos in these statuses show the delete button.
  final Set<PhotoStatus>? removableStatuses;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.incidentsReportPhotosOptional,
              style: GatesTypography.label,
            ),
            Text(
              '${photos.length} / $maxIncidentPhotos',
              style: context.gatesText.caption.copyWith(height: 16 / 12),
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
                PhotoTile(
                  photo: photo,
                  canRemove:
                      onRemove != null &&
                      (removableStatuses?.contains(photo.status) ?? true),
                  onRemove: () => onRemove?.call(photo),
                  onRetry: () => onRetry?.call(photo),
                ),
            ],
          ),
        if (showAdd && photos.length < maxIncidentPhotos) ...[
          if (photos.isNotEmpty) const SizedBox(height: GatesSpacing.space12),
          AddPhotosCard(
            title: photos.isEmpty
                ? context.l10n.incidentsReportAddPhotos
                : context.l10n.incidentsReportAddMorePhotos,
            onTap: onAdd,
          ),
        ],
      ],
    );
  }
}

class AddPhotosCard extends StatelessWidget {
  const AddPhotosCard({super.key, required this.title, required this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GatesRadius.radius16),
        side: BorderSide(color: context.palette.borderDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(GatesSpacing.space16),
          child: Row(
            children: [
              Icon(
                Icons.photo_camera_outlined,
                size: 24,
                color: context.palette.textPrimary,
              ),
              const SizedBox(width: GatesSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GatesTypography.label.copyWith(
                        color: context.palette.textBrand,
                      ),
                    ),
                    const SizedBox(height: GatesSpacing.space4),
                    Text(
                      context.l10n.incidentsReportUpToPhotos(maxIncidentPhotos),
                      style: context.gatesText.caption.copyWith(
                        height: 16 / 12,
                      ),
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
class PhotoTile extends StatelessWidget {
  const PhotoTile({
    super.key,
    required this.photo,
    required this.canRemove,
    required this.onRemove,
    required this.onRetry,
  });

  final ReportPhoto photo;
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
                ? Image.file(File(photo.file!.path), fit: BoxFit.cover)
                : Image.network(photo.url!, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  canRemove && status != PhotoStatus.uploading
                      ? Semantics(
                          button: true,
                          label: context.l10n.incidentsReportRemovePhoto,
                          excludeSemantics: true,
                          onTap: onRemove,
                          child: GestureDetector(
                            onTap: onRemove,
                            behavior: HitTestBehavior.opaque,
                            // 44pt touch target around the 28pt chip.
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: context.palette.bgSurface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 20,
                                    color: context.palette.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(height: 44),
                  if (status == PhotoStatus.uploading)
                    StatusPill(
                      label: context.l10n.incidentsReportUploading,
                      background: context.palette.bgSurface,
                      foreground: context.palette.textBrand,
                    ),
                  if (status == PhotoStatus.error)
                    Semantics(
                      button: true,
                      label: context.l10n.incidentsReportRetryUploadPhoto,
                      excludeSemantics: true,
                      onTap: onRetry,
                      child: GestureDetector(
                        onTap: onRetry,
                        child: StatusPill(
                          label: context.l10n.incidentsReportRetry,
                          background: context.palette.statusErrorBg,
                          foreground: context.palette.statusError,
                        ),
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

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
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
        style: context.gatesText.caption.copyWith(
          color: foreground,
          height: 16 / 12,
        ),
      ),
    );
  }
}

/// Figma "Fotografías / Bottom sheet" (node `473:2395`): a floating white
/// sheet with the two sources, plus a separate "Cancelar" pill below it.
class PhotoSourceSheet extends StatelessWidget {
  const PhotoSourceSheet({
    super.key,
    required this.onPick,
    required this.onCancel,
  });

  final ValueChanged<PhotoSource> onPick;
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
                color: context.palette.bgSurface,
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
                          context.l10n.incidentsReportAddPhotos,
                          style: GatesTypography.headingSmall,
                        ),
                      ),
                      InkResponse(
                        onTap: onCancel,
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: context.palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: GatesSpacing.space16),
                  Text(
                    context.l10n.incidentsReportPhotoSourceBody,
                    style: GatesTypography.body.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: GatesSpacing.space16),
                  SheetAction(
                    label: context.l10n.incidentsReportTakePhoto,
                    onTap: () => onPick(PhotoSource.camera),
                  ),
                  const SizedBox(height: GatesSpacing.space8),
                  SheetAction(
                    label: context.l10n.incidentsReportChooseGallery,
                    onTap: () => onPick(PhotoSource.gallery),
                  ),
                ],
              ),
            ),
            const SizedBox(height: GatesSpacing.space12),
            SheetAction(
              label: context.l10n.incidentsReportCancel,
              onTap: onCancel,
              background: context.palette.bgSurface,
              height: 52,
            ),
          ],
        ),
      ),
    );
  }
}

class SheetAction extends StatelessWidget {
  const SheetAction({
    super.key,
    required this.label,
    required this.onTap,
    this.background,
    this.height = 56,
  });

  final String label;
  final VoidCallback onTap;
  final Color? background;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background ?? context.palette.bgSubtle,
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
                color: context.palette.textBrand,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

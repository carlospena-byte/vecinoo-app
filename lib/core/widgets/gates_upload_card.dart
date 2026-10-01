import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../l10n/l10n.dart';

enum GatesUploadState { empty, ready, uploading, error }

/// Figma "Upload" card. Empty / ready (a file is picked) / uploading / error
/// each get their own border and copy; the caller owns the state and the
/// actual picking and uploading.
class GatesUploadCard extends StatelessWidget {
  const GatesUploadCard({
    super.key,
    required this.title,
    required this.state,
    required this.onPick,
    required this.onRemove,
    this.emptyDescription,
    this.fileLabel,
    this.errorDescription,
  });

  /// Heading in the empty state, e.g. "Documento de identidad *".
  final String title;
  final GatesUploadState state;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  /// Defaults to the localized "JPG or PNG · up to 10 MB".
  final String? emptyDescription;

  /// "file.jpg · 2.4 MB" once a file is picked.
  final String? fileLabel;
  final String? errorDescription;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isError = state == GatesUploadState.error;
    final isReady = state == GatesUploadState.ready;
    final heading = switch (state) {
      GatesUploadState.empty => title,
      GatesUploadState.ready => l10n.commonUploadReady,
      GatesUploadState.uploading => l10n.commonUploadUploading,
      GatesUploadState.error => title,
    };
    final description = switch (state) {
      GatesUploadState.empty => emptyDescription ?? l10n.commonUploadFormats,
      GatesUploadState.ready => fileLabel ?? '',
      GatesUploadState.uploading => fileLabel ?? l10n.commonUploadPreparing,
      GatesUploadState.error =>
        errorDescription ?? l10n.commonUploadErrorDefault,
    };
    final (actionLabel, action) = switch (state) {
      GatesUploadState.empty => (l10n.commonUploadDocument, onPick),
      GatesUploadState.ready || GatesUploadState.uploading => (
        l10n.commonRemove,
        state == GatesUploadState.uploading ? null : onRemove,
      ),
      GatesUploadState.error => (l10n.commonChooseFile, onPick),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isError
            ? context.palette.statusErrorBg
            : context.palette.bgSurface,
        border: Border.all(
          color: isError
              ? context.palette.statusError
              : isReady
              ? context.palette.borderFocus
              : context.palette.borderDefault,
          width: isReady ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(GatesRadius.radius16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            heading,
            style: GatesTypography.label.copyWith(
              color: isError ? context.palette.statusError : null,
            ),
          ),
          const SizedBox(height: GatesSpacing.space8),
          Text(description, style: context.gatesText.caption),
          const SizedBox(height: GatesSpacing.space8),
          InkWell(
            onTap: action,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 32),
              child: Align(
                alignment: Alignment.centerLeft,
                child: state == GatesUploadState.uploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        actionLabel,
                        style: GatesTypography.label.copyWith(
                          color: context.palette.textBrand,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

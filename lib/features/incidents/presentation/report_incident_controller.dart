import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show XFile;

import '../../../core/error/failure.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/incident.dart';
import 'incident_edit_args.dart';
import 'incidents_controller.dart';
import 'photo_picker.dart';

const maxIncidentPhotos = 10;

/// Which screen of the "report an incident" flow is showing.
enum ReportPhase { form, sending, photoError, sent }

enum PhotoStatus { ready, uploading, done, error }

/// One photo in the report: either a local file waiting to upload, or an
/// attachment already stored on the server (edit mode).
class ReportPhoto {
  const ReportPhoto._({
    required this.id,
    required this.status,
    this.file,
    this.attachment,
  });

  ReportPhoto.local(XFile file, {required int id})
    : this._(id: id, status: PhotoStatus.ready, file: file);

  ReportPhoto.stored(IncidentAttachment attachment, {required int id})
    : this._(id: id, status: PhotoStatus.done, attachment: attachment);

  final int id;
  final PhotoStatus status;
  final XFile? file;
  final IncidentAttachment? attachment;

  /// Remote URL of a stored photo, null for local ones.
  String? get url => attachment?.url;

  ReportPhoto withStatus(PhotoStatus status) =>
      ReportPhoto._(id: id, status: status, file: file, attachment: attachment);
}

/// One-off notifications the screen turns into toasts / navigation.
sealed class ReportEvent {
  const ReportEvent();
}

class PhotoLimitReached extends ReportEvent {
  const PhotoLimitReached({required this.added});

  /// How many of the picked photos still fit.
  final int added;
}

class PhotosOpenFailed extends ReportEvent {
  const PhotosOpenFailed();
}

class SaveFailed extends ReportEvent {
  const SaveFailed(this.failure);
  final Failure failure;
}

class SendFailed extends ReportEvent {
  const SendFailed(this.failure);
  final Failure failure;
}

/// Edit mode finished: the screen closes and confirms.
class EditSaved extends ReportEvent {
  const EditSaved();
}

class ReportIncidentState {
  const ReportIncidentState({
    this.phase = ReportPhase.form,
    this.incidentTypeId,
    this.photos = const [],
    this.incidentId,
    this.removedAttachments = const [],
    this.sentTitle = '',
    this.sentCategory,
    this.isDirty = false,
  });

  final ReportPhase phase;
  final String? incidentTypeId;
  final List<ReportPhoto> photos;

  /// Set once the row exists, so retrying photo uploads never creates a
  /// second incident.
  final String? incidentId;

  /// Server photos the user removed while editing; deleted on save.
  final List<IncidentAttachment> removedAttachments;

  /// Snapshot shown on the confirmation screen.
  final String sentTitle;
  final String? sentCategory;

  /// Whether the draft differs from what was loaded (edit mode only uses it).
  final bool isDirty;

  bool get hasPhotoErrors => photos.any((p) => p.status == PhotoStatus.error);

  int get uploadedCount =>
      photos.where((p) => p.status == PhotoStatus.done).length;

  ReportIncidentState copyWith({
    ReportPhase? phase,
    Object? incidentTypeId = _keep,
    List<ReportPhoto>? photos,
    String? incidentId,
    List<IncidentAttachment>? removedAttachments,
    String? sentTitle,
    Object? sentCategory = _keep,
    bool? isDirty,
  }) {
    return ReportIncidentState(
      phase: phase ?? this.phase,
      incidentTypeId: identical(incidentTypeId, _keep)
          ? this.incidentTypeId
          : incidentTypeId as String?,
      photos: photos ?? this.photos,
      incidentId: incidentId ?? this.incidentId,
      removedAttachments: removedAttachments ?? this.removedAttachments,
      sentTitle: sentTitle ?? this.sentTitle,
      sentCategory: identical(sentCategory, _keep)
          ? this.sentCategory
          : sentCategory as String?,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

const _keep = Object();

/// Drives the whole report flow (create or edit): form state, the
/// create-then-upload-photos sequence with per-photo retry, and dirty
/// tracking. The screen only renders [ReportIncidentState] and forwards user
/// actions; text fields stay widget-owned and are handed in on submit.
class ReportIncidentController extends Notifier<ReportIncidentState> {
  ReportIncidentController(this.editing);

  /// Set when editing an existing incident.
  final IncidentEditArgs? editing;

  final _events = StreamController<ReportEvent>.broadcast();
  bool _disposed = false;
  int _nextPhotoId = 0;
  String _baselineSignature = '';
  String _draftTitle = '';
  String _draftDescription = '';

  /// One-off events (toasts, closing the screen).
  Stream<ReportEvent> get events => _events.stream;

  bool get isEditing => editing != null;

  @override
  ReportIncidentState build() {
    ref.onDispose(() {
      _disposed = true;
      _events.close();
    });
    final args = editing;
    if (args == null) return const ReportIncidentState();
    final initial = ReportIncidentState(
      incidentId: args.incident.id,
      incidentTypeId: args.incident.incidentTypeId,
      photos: [
        for (final a in args.attachments)
          ReportPhoto.stored(a, id: _nextPhotoId++),
      ],
    );
    _draftTitle = args.incident.title;
    _baselineSignature = _signature(initial);
    return initial;
  }

  String _signature(ReportIncidentState s) =>
      '$_draftTitle|$_draftDescription|${s.incidentTypeId}|'
      '${s.photos.length}|${s.removedAttachments.length}';

  /// The editor reports its text; only rebuilds when the dirty flag flips.
  void updateDraft({required String title, required String description}) {
    _draftTitle = title;
    _draftDescription = description;
    _syncDirty();
  }

  /// Edit mode loads the description into the rich editor asynchronously;
  /// the baseline must then reflect the text as loaded.
  void markLoadedDraft({required String title, required String description}) {
    _draftTitle = title;
    _draftDescription = description;
    _baselineSignature = _signature(state);
    _syncDirty();
  }

  void _syncDirty() {
    final dirty = _signature(state) != _baselineSignature;
    if (dirty != state.isDirty) state = state.copyWith(isDirty: dirty);
  }

  void selectType(String id) {
    state = state.copyWith(incidentTypeId: id);
    _syncDirty();
  }

  Future<void> addPhotos(PhotoSource source) async {
    final remaining = maxIncidentPhotos - state.photos.length;
    if (remaining <= 0) return;
    try {
      var picked = await ref.read(photoPickerProvider).pick(source);
      if (picked.isEmpty || _disposed) return;
      if (picked.length > remaining) {
        _events.add(PhotoLimitReached(added: remaining));
        picked = picked.take(remaining).toList();
      }
      state = state.copyWith(
        photos: [
          ...state.photos,
          for (final file in picked)
            ReportPhoto.local(file, id: _nextPhotoId++),
        ],
      );
      _syncDirty();
      // After the report already exists, new photos go up right away.
      if (state.incidentId != null) await uploadPending();
    } catch (_) {
      if (!_disposed) _events.add(const PhotosOpenFailed());
    }
  }

  void removePhoto(int photoId) {
    final photo = state.photos.firstWhere((p) => p.id == photoId);
    final attachment = photo.attachment;
    state = state.copyWith(
      photos: [
        for (final p in state.photos)
          if (p.id != photoId) p,
      ],
      removedAttachments: attachment == null
          ? null
          : [...state.removedAttachments, attachment],
    );
    _syncDirty();
  }

  /// Creates (or updates) the incident, then uploads the pending photos.
  Future<void> submit({required String title, String? descriptionHtml}) async {
    final membership = ref.read(selectedMembershipProvider).value;
    final trimmed = title.trim();
    if (membership == null || trimmed.isEmpty) return;

    final types =
        ref.read(incidentTypesProvider(membership.residentialId)).value ??
        const <IncidentType>[];
    state = state.copyWith(
      phase: ReportPhase.sending,
      sentTitle: trimmed,
      sentCategory: types
          .where((t) => t.id == state.incidentTypeId)
          .map((t) => t.name)
          .firstOrNull,
    );

    final repository = ref.read(incidentsRepositoryProvider);
    if (isEditing) {
      try {
        await repository.updateIncident(
          incidentId: state.incidentId!,
          title: trimmed,
          description: descriptionHtml,
          incidentTypeId: state.incidentTypeId,
        );
        for (final attachment in state.removedAttachments.toList()) {
          await repository.deleteAttachment(attachment);
          if (_disposed) return;
          state = state.copyWith(
            removedAttachments: [
              for (final a in state.removedAttachments)
                if (a.id != attachment.id) a,
            ],
          );
        }
        ref.invalidate(incidentsListProvider(membership.residentialId));
      } catch (error) {
        if (_disposed) return;
        // Keep every change so the user can retry.
        state = state.copyWith(phase: ReportPhase.form);
        _events.add(SaveFailed(Failure.from(error)));
        return;
      }
      await uploadPending();
      return;
    }

    try {
      final id =
          state.incidentId ??
          await repository.createIncident(
            residentialId: membership.residentialId,
            unitId: membership.unitId,
            title: trimmed,
            description: descriptionHtml,
            incidentTypeId: state.incidentTypeId,
          );
      if (_disposed) return;
      state = state.copyWith(incidentId: id);
      ref.invalidate(incidentsListProvider(membership.residentialId));
    } catch (error) {
      if (_disposed) return;
      state = state.copyWith(phase: ReportPhase.form);
      _events.add(SendFailed(Failure.from(error)));
      return;
    }
    await uploadPending();
  }

  /// Uploads every photo that is waiting (or failed before), one at a time,
  /// then lands on the error screen if any are left, or finishes.
  Future<void> uploadPending() async {
    final membership = ref.read(selectedMembershipProvider).value;
    final incidentId = state.incidentId;
    if (membership == null || incidentId == null) return;

    state = state.copyWith(phase: ReportPhase.sending);
    final repository = ref.read(incidentsRepositoryProvider);
    for (final photo in state.photos.toList()) {
      if (photo.status != PhotoStatus.ready &&
          photo.status != PhotoStatus.error) {
        continue;
      }
      if (_disposed) return;
      _setStatus(photo.id, PhotoStatus.uploading);
      try {
        final file = photo.file!;
        await repository.uploadPhoto(
          residentialId: membership.residentialId,
          incidentId: incidentId,
          bytes: await file.readAsBytes(),
          extension: file.path.split('.').last,
        );
        if (_disposed) return;
        _setStatus(photo.id, PhotoStatus.done);
      } catch (_) {
        if (_disposed) return;
        _setStatus(photo.id, PhotoStatus.error);
      }
    }
    if (_disposed) return;
    if (state.hasPhotoErrors) {
      state = state.copyWith(phase: ReportPhase.photoError);
    } else {
      finish();
    }
  }

  void _setStatus(int photoId, PhotoStatus status) {
    state = state.copyWith(
      photos: [
        for (final p in state.photos)
          p.id == photoId ? p.withStatus(status) : p,
      ],
    );
  }

  /// Edit mode returns to the detail once the server confirmed everything;
  /// a new report shows the confirmation screen.
  void finish() {
    if (isEditing) {
      _events.add(const EditSaved());
    } else {
      state = state.copyWith(phase: ReportPhase.sent);
    }
  }
}

final reportIncidentControllerProvider = NotifierProvider.autoDispose
    .family<ReportIncidentController, ReportIncidentState, IncidentEditArgs?>(
      ReportIncidentController.new,
    );

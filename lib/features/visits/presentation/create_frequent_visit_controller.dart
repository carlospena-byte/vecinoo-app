import 'dart:async';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show XFile;

import '../../../core/error/failure.dart';
import '../../../core/widgets/gates_phone_field.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/visit.dart';
import 'visits_controller.dart';

const maxFrequentDocumentBytes = 10 * 1024 * 1024;

const _defaultStart = TimeOfDay(hour: 8, minute: 0);
const _defaultEnd = TimeOfDay(hour: 22, minute: 0);

/// Why the chosen ID photo was rejected.
enum DocumentError { tooBig }

/// What kept the schedule step from being submitted.
enum FrequentVisitIssue { eachBlockNeedsDay, startBeforeEnd }

/// "+50499999999" -> country chip + local number.
({GatesCountryCode country, String local}) splitFrequentPhone(String? phone) {
  if (phone == null || phone.isEmpty) {
    return (country: gatesCountryCodes.first, local: '');
  }
  final matches =
      gatesCountryCodes.where((c) => phone.startsWith(c.dialCode)).toList()
        ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
  if (matches.isEmpty) return (country: gatesCountryCodes.first, local: phone);
  final country = matches.first;
  return (country: country, local: phone.substring(country.dialCode.length));
}

class CreateFrequentVisitState {
  const CreateFrequentVisitState({
    this.step = 0,
    this.role = VisitorRole.familiar,
    required this.country,
    this.document,
    this.documentSize = 0,
    this.documentMissing = false,
    this.documentError,
    this.keepsExistingDocument = false,
    this.hasVehicle = false,
    this.recurrence = Recurrence.monFri,
    this.scheduleType = ScheduleType.allDay,
    this.scheduleStart = _defaultStart,
    this.scheduleEnd = _defaultEnd,
    this.blocks = const [],
    this.notifyOnArrival = true,
    this.isSubmitting = false,
  });

  final int step;
  final VisitorRole role;
  final GatesCountryCode country;
  final XFile? document;

  /// Size in bytes of [document] (for the "1.2 MB" label).
  final int documentSize;
  final bool documentMissing;
  final DocumentError? documentError;

  /// The visit already has an ID photo on file; a new one is only needed if
  /// the resident removes it to replace it.
  final bool keepsExistingDocument;
  final bool hasVehicle;
  final Recurrence recurrence;
  final ScheduleType scheduleType;
  final TimeOfDay scheduleStart;
  final TimeOfDay scheduleEnd;
  final List<ScheduleBlock> blocks;
  final bool notifyOnArrival;
  final bool isSubmitting;

  bool get hasDocument => document != null || keepsExistingDocument;

  /// Days another block (not the one at [index]) already covers.
  Set<String> daysTakenByOthers(int index) => {
    for (var i = 0; i < blocks.length; i++)
      if (i != index) ...blocks[i].days,
  };

  /// Every day already belongs to a block: nothing left to add.
  bool get allDaysTaken =>
      blocks.expand((b) => b.days).toSet().length >= weekdayKeys.length;

  CreateFrequentVisitState copyWith({
    int? step,
    VisitorRole? role,
    GatesCountryCode? country,
    Object? document = _keep,
    int? documentSize,
    bool? documentMissing,
    Object? documentError = _keep,
    bool? keepsExistingDocument,
    bool? hasVehicle,
    Recurrence? recurrence,
    ScheduleType? scheduleType,
    TimeOfDay? scheduleStart,
    TimeOfDay? scheduleEnd,
    List<ScheduleBlock>? blocks,
    bool? notifyOnArrival,
    bool? isSubmitting,
  }) {
    return CreateFrequentVisitState(
      step: step ?? this.step,
      role: role ?? this.role,
      country: country ?? this.country,
      document: identical(document, _keep) ? this.document : document as XFile?,
      documentSize: documentSize ?? this.documentSize,
      documentMissing: documentMissing ?? this.documentMissing,
      documentError: identical(documentError, _keep)
          ? this.documentError
          : documentError as DocumentError?,
      keepsExistingDocument:
          keepsExistingDocument ?? this.keepsExistingDocument,
      hasVehicle: hasVehicle ?? this.hasVehicle,
      recurrence: recurrence ?? this.recurrence,
      scheduleType: scheduleType ?? this.scheduleType,
      scheduleStart: scheduleStart ?? this.scheduleStart,
      scheduleEnd: scheduleEnd ?? this.scheduleEnd,
      blocks: blocks ?? this.blocks,
      notifyOnArrival: notifyOnArrival ?? this.notifyOnArrival,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

const _keep = Object();

/// One-off notifications the screen turns into toasts / navigation.
sealed class CreateFrequentVisitEvent {
  const CreateFrequentVisitEvent();
}

class FrequentVisitInvalid extends CreateFrequentVisitEvent {
  const FrequentVisitInvalid(this.issue);
  final FrequentVisitIssue issue;
}

class FrequentVisitSaved extends CreateFrequentVisitEvent {
  const FrequentVisitSaved({required this.updated});

  /// True when an existing visit was edited, false when one was created.
  final bool updated;
}

class FrequentVisitSaveFailed extends CreateFrequentVisitEvent {
  const FrequentVisitSaveFailed(this.failure);
  final Failure failure;
}

/// Owns the frequent-visit form (create and edit): everything but the text
/// fields, which the screen keeps and hands over on [submit].
class CreateFrequentVisitController extends Notifier<CreateFrequentVisitState> {
  CreateFrequentVisitController(this.editing);

  /// When set, the form is prefilled from this visit and saving updates it.
  final Visit? editing;

  final _events = StreamController<CreateFrequentVisitEvent>.broadcast();
  bool _disposed = false;

  Stream<CreateFrequentVisitEvent> get events => _events.stream;

  bool get isEditing => editing != null;

  @override
  CreateFrequentVisitState build() {
    ref.onDispose(() {
      _disposed = true;
      _events.close();
    });
    final visit = editing;
    if (visit == null) {
      return CreateFrequentVisitState(country: gatesCountryCodes.first);
    }
    final recurrence = visit.recurrence ?? Recurrence.monFri;
    final start = visit.scheduleStart ?? _defaultStart;
    final end = visit.scheduleEnd ?? _defaultEnd;
    var blocks = <ScheduleBlock>[];
    if (recurrence == Recurrence.custom) {
      final saved = visit.scheduleBlocks;
      blocks = saved != null && saved.isNotEmpty
          ? [
              for (final b in saved) b.copyWith(days: {...b.days}),
            ]
          // Saved before blocks existed: rebuild a single block.
          : [
              ScheduleBlock(
                days: {...?visit.recurrenceDays},
                start: start,
                end: end,
              ),
            ];
    }
    return CreateFrequentVisitState(
      role: visit.visitorRole ?? VisitorRole.familiar,
      country: splitFrequentPhone(visit.phone).country,
      keepsExistingDocument: visit.idPhotoPath != null,
      hasVehicle: visit.hasVehicle,
      recurrence: recurrence,
      scheduleType: visit.scheduleType ?? ScheduleType.allDay,
      scheduleStart: start,
      scheduleEnd: end,
      blocks: blocks,
      notifyOnArrival: visit.notifyOnArrival,
    );
  }

  void setRole(VisitorRole role) => state = state.copyWith(role: role);

  void setCountry(GatesCountryCode country) =>
      state = state.copyWith(country: country);

  void setHasVehicle(bool value) => state = state.copyWith(hasVehicle: value);

  void setNotifyOnArrival(bool value) =>
      state = state.copyWith(notifyOnArrival: value);

  void setScheduleType(ScheduleType type) =>
      state = state.copyWith(scheduleType: type);

  void setScheduleStart(TimeOfDay time) =>
      state = state.copyWith(scheduleStart: time);

  void setScheduleEnd(TimeOfDay time) =>
      state = state.copyWith(scheduleEnd: time);

  /// A photo was picked: rejected when it is over the size limit.
  Future<void> setDocument(XFile file) async {
    final size = await file.length();
    if (_disposed) return;
    if (size > maxFrequentDocumentBytes) {
      state = state.copyWith(
        document: null,
        documentError: DocumentError.tooBig,
      );
    } else {
      state = state.copyWith(
        document: file,
        documentSize: size,
        keepsExistingDocument: false,
        documentError: null,
        documentMissing: false,
      );
    }
  }

  void removeDocument() => state = state.copyWith(
    document: null,
    documentError: null,
    keepsExistingDocument: false,
  );

  /// Step 1 -> step 2. [formValid] is the verdict of the screen's form
  /// fields; the document is checked here.
  void next({required bool formValid}) {
    if (!formValid) return;
    if (!state.hasDocument) {
      state = state.copyWith(documentMissing: true);
      return;
    }
    state = state.copyWith(step: 1);
  }

  void backToFirstStep() => state = state.copyWith(step: 0);

  void setRecurrence(Recurrence value) {
    final needsBlock = value == Recurrence.custom && state.blocks.isEmpty;
    state = state.copyWith(
      recurrence: value,
      blocks: needsBlock
          ? [
              const ScheduleBlock(
                days: {'mon', 'tue', 'wed', 'thu', 'fri'},
                start: _defaultStart,
                end: _defaultEnd,
              ),
            ]
          : null,
    );
  }

  void addBlock() => state = state.copyWith(
    blocks: [
      ...state.blocks,
      const ScheduleBlock(days: {}, start: _defaultStart, end: _defaultEnd),
    ],
  );

  void removeBlock(int index) => state = state.copyWith(
    blocks: [
      for (var i = 0; i < state.blocks.length; i++)
        if (i != index) state.blocks[i],
    ],
  );

  void toggleBlockDay(int index, String day) {
    final days = {...state.blocks[index].days};
    if (!days.remove(day)) days.add(day);
    _updateBlock(index, (b) => b.copyWith(days: days));
  }

  void setBlockStart(int index, TimeOfDay time) =>
      _updateBlock(index, (b) => b.copyWith(start: time));

  void setBlockEnd(int index, TimeOfDay time) =>
      _updateBlock(index, (b) => b.copyWith(end: time));

  void _updateBlock(int index, ScheduleBlock Function(ScheduleBlock) update) {
    state = state.copyWith(
      blocks: [
        for (var i = 0; i < state.blocks.length; i++)
          if (i == index) update(state.blocks[i]) else state.blocks[i],
      ],
    );
  }

  bool _isBefore(TimeOfDay a, TimeOfDay b) =>
      a.hour * 60 + a.minute < b.hour * 60 + b.minute;

  FrequentVisitIssue? _validateSchedule() {
    if (state.recurrence == Recurrence.custom) {
      for (final block in state.blocks) {
        if (block.days.isEmpty) return FrequentVisitIssue.eachBlockNeedsDay;
        if (!_isBefore(block.start, block.end)) {
          return FrequentVisitIssue.startBeforeEnd;
        }
      }
    } else if (state.scheduleType == ScheduleType.custom &&
        !_isBefore(state.scheduleStart, state.scheduleEnd)) {
      return FrequentVisitIssue.startBeforeEnd;
    }
    return null;
  }

  /// Saves the visit. The text fields come straight from the screen:
  /// [phoneDigits] is the local number (the country dial code is added here).
  Future<void> submit({
    required String name,
    required String phoneDigits,
    required String plate,
    required String notes,
  }) async {
    if (state.isSubmitting) return;
    final issue = _validateSchedule();
    if (issue != null) {
      _events.add(FrequentVisitInvalid(issue));
      return;
    }
    final membership = ref.read(selectedMembershipProvider).value;
    final document = state.document;
    if (membership == null) return;
    if (document == null && !state.keepsExistingDocument) return;

    state = state.copyWith(isSubmitting: true);
    final repository = ref.read(visitsRepositoryProvider);
    try {
      final photoPath = document == null
          ? null
          : await repository.uploadVisitorDocument(
              residentialId: membership.residentialId,
              bytes: await document.readAsBytes(),
              extension: document.path.split('.').last,
            );
      final digits = phoneDigits.trim();
      final phone = digits.isEmpty
          ? null
          : '${state.country.dialCode}${digits.replaceAll(RegExp(r'[^0-9]'), '')}';
      final blocks = state.recurrence == Recurrence.custom
          ? [
              for (final b in state.blocks) b.copyWith(days: {...b.days}),
            ]
          : null;
      final trimmedNotes = notes.trim().isEmpty ? null : notes.trim();
      final visit = editing;
      if (visit != null) {
        await repository.updateFrequentVisit(
          visitId: visit.id,
          name: name.trim(),
          phone: phone,
          visitorRole: state.role,
          idPhotoPath: photoPath,
          hasVehicle: state.hasVehicle,
          plate: plate.trim().toUpperCase(),
          recurrence: state.recurrence,
          scheduleType: state.scheduleType,
          scheduleStart: state.scheduleStart,
          scheduleEnd: state.scheduleEnd,
          scheduleBlocks: blocks,
          notifyOnArrival: state.notifyOnArrival,
          notes: trimmedNotes,
        );
      } else {
        await repository.createFrequentVisit(
          residentialId: membership.residentialId,
          unitId: membership.unitId,
          name: name.trim(),
          phone: phone,
          visitorRole: state.role,
          idPhotoPath: photoPath!,
          hasVehicle: state.hasVehicle,
          plate: plate.trim().toUpperCase(),
          recurrence: state.recurrence,
          scheduleType: state.scheduleType,
          scheduleStart: state.scheduleStart,
          scheduleEnd: state.scheduleEnd,
          scheduleBlocks: blocks,
          notifyOnArrival: state.notifyOnArrival,
          notes: trimmedNotes,
        );
      }
      if (_disposed) return;
      // Stays "submitting" on success: the screen is about to be left.
      _events.add(FrequentVisitSaved(updated: visit != null));
    } catch (error) {
      if (_disposed) return;
      _events.add(FrequentVisitSaveFailed(Failure.from(error)));
      state = state.copyWith(isSubmitting: false);
    }
  }
}

final createFrequentVisitControllerProvider = NotifierProvider.autoDispose
    .family<CreateFrequentVisitController, CreateFrequentVisitState, Visit?>(
      CreateFrequentVisitController.new,
    );

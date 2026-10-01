import 'dart:async';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/visit.dart';
import 'visits_controller.dart';

class CreateFastlaneVisitState {
  const CreateFastlaneVisitState({
    required this.visitDate,
    required this.arrivalTime,
    this.isSubmitting = false,
  });

  final DateTime visitDate;
  final TimeOfDay arrivalTime;
  final bool isSubmitting;

  CreateFastlaneVisitState copyWith({
    DateTime? visitDate,
    TimeOfDay? arrivalTime,
    bool? isSubmitting,
  }) {
    return CreateFastlaneVisitState(
      visitDate: visitDate ?? this.visitDate,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

sealed class CreateFastlaneVisitEvent {
  const CreateFastlaneVisitEvent();
}

/// A new invitation was created: the screen opens its share-link page.
class FastlaneCreated extends CreateFastlaneVisitEvent {
  const FastlaneCreated(this.visit);
  final Visit visit;
}

/// An existing pending invitation was updated.
class FastlaneUpdated extends CreateFastlaneVisitEvent {
  const FastlaneUpdated();
}

class FastlaneCreateFailed extends CreateFastlaneVisitEvent {
  const FastlaneCreateFailed(this.failure);
  final Failure failure;
}

class FastlaneUpdateFailed extends CreateFastlaneVisitEvent {
  const FastlaneUpdateFailed(this.failure);
  final Failure failure;
}

/// Owns the FastLane form's date/time and the create/update call; the screen
/// keeps the text controllers.
class CreateFastlaneVisitController extends Notifier<CreateFastlaneVisitState> {
  CreateFastlaneVisitController(this.editing);

  /// When set, [submit] updates this invitation instead of creating one.
  final Visit? editing;

  final _events = StreamController<CreateFastlaneVisitEvent>.broadcast();
  bool _disposed = false;

  Stream<CreateFastlaneVisitEvent> get events => _events.stream;

  @override
  CreateFastlaneVisitState build() {
    ref.onDispose(() {
      _disposed = true;
      _events.close();
    });
    final editing = this.editing;
    return CreateFastlaneVisitState(
      visitDate: editing?.validFrom ?? DateTime.now(),
      arrivalTime: editing == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(editing.validFrom),
    );
  }

  void setVisitDate(DateTime date) => state = state.copyWith(visitDate: date);

  void setArrivalTime(TimeOfDay time) =>
      state = state.copyWith(arrivalTime: time);

  Future<void> submit({required String name, required String notes}) async {
    if (state.isSubmitting) return;
    final membership = ref.read(selectedMembershipProvider).value;
    if (membership == null) return;

    state = state.copyWith(isSubmitting: true);
    final repository = ref.read(visitsRepositoryProvider);
    final trimmedName = name.trim();
    final trimmedNotes = notes.trim().isEmpty ? null : notes.trim();
    final editing = this.editing;
    try {
      if (editing != null) {
        await repository.updateFastlaneVisit(
          visitId: editing.id,
          name: trimmedName,
          visitDate: state.visitDate,
          arrivalTime: state.arrivalTime,
          notes: trimmedNotes,
        );
        if (_disposed) return;
        _events.add(const FastlaneUpdated());
      } else {
        final result = await repository.createFastlaneVisit(
          residentialId: membership.residentialId,
          unitId: membership.unitId,
          name: trimmedName,
          visitDate: state.visitDate,
          arrivalTime: state.arrivalTime,
          notes: trimmedNotes,
        );
        if (_disposed) return;
        _events.add(FastlaneCreated(result));
      }
    } catch (error) {
      if (_disposed) return;
      final failure = Failure.from(error);
      _events.add(
        editing != null
            ? FastlaneUpdateFailed(failure)
            : FastlaneCreateFailed(failure),
      );
    } finally {
      // After a successful update the screen pops; the original also kept the
      // button loading in that case, which is invisible once popped.
      if (!_disposed) state = state.copyWith(isSubmitting: false);
    }
  }
}

final createFastlaneVisitControllerProvider = NotifierProvider.autoDispose
    .family<CreateFastlaneVisitController, CreateFastlaneVisitState, Visit?>(
      CreateFastlaneVisitController.new,
    );

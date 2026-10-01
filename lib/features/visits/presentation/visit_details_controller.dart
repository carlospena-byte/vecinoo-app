import 'dart:async';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/provider_catalog_item.dart';
import '../domain/visit.dart';
import 'visits_controller.dart';

/// Args for the delivery/provider visit details screen: either a catalog
/// [provider] was picked, or the resident chose "Otro" / a no-results
/// fallback, in which case [provider] is null and a free-text name is asked.
class VisitDetailsArgs {
  const VisitDetailsArgs({required this.kind, this.provider});

  final ProviderKind kind;
  final ProviderCatalogItem? provider;
}

class VisitDetailsState {
  const VisitDetailsState({
    required this.kind,
    required this.provider,
    required this.visitDate,
    required this.arrivalTime,
    this.isSubmitting = false,
  });

  final ProviderKind kind;

  /// Null means "Otro": the resident types a name instead.
  final ProviderCatalogItem? provider;
  final DateTime visitDate;
  final TimeOfDay? arrivalTime;
  final bool isSubmitting;

  /// Providers (vendors) get access for the whole day; deliveries need an
  /// expected arrival time.
  bool get needsTime => kind != ProviderKind.proveedor;

  VisitDetailsState copyWith({
    ProviderKind? kind,
    Object? provider = _keep,
    DateTime? visitDate,
    TimeOfDay? arrivalTime,
    bool? isSubmitting,
  }) {
    return VisitDetailsState(
      kind: kind ?? this.kind,
      provider: identical(provider, _keep)
          ? this.provider
          : provider as ProviderCatalogItem?,
      visitDate: visitDate ?? this.visitDate,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

const _keep = Object();

/// What happened when the resident pressed "Autorizar".
sealed class VisitDetailsEvent {
  const VisitDetailsEvent();
}

/// Nobody was chosen yet: the screen should open the "¿Quién viene?" sheet.
class NeedsProvider extends VisitDetailsEvent {
  const NeedsProvider();
}

class VisitAuthorized extends VisitDetailsEvent {
  const VisitAuthorized();
}

class AuthorizeFailed extends VisitDetailsEvent {
  const AuthorizeFailed(this.failure);
  final Failure failure;
}

/// Owns the delivery/provider visit form's state and the authorize call; the
/// screen only renders it and keeps the text controllers.
class VisitDetailsController extends Notifier<VisitDetailsState> {
  VisitDetailsController(this.args);

  final VisitDetailsArgs args;

  final _events = StreamController<VisitDetailsEvent>.broadcast();
  bool _disposed = false;

  Stream<VisitDetailsEvent> get events => _events.stream;

  @override
  VisitDetailsState build() {
    ref.onDispose(() {
      _disposed = true;
      _events.close();
    });
    return VisitDetailsState(
      kind: args.kind,
      provider: args.provider,
      visitDate: DateTime.now(),
      arrivalTime: TimeOfDay.now(),
    );
  }

  void changeProvider(ProviderCatalogItem? provider, ProviderKind kind) {
    state = state.copyWith(provider: provider, kind: kind);
  }

  void setVisitDate(DateTime date) => state = state.copyWith(visitDate: date);

  void setArrivalTime(TimeOfDay time) =>
      state = state.copyWith(arrivalTime: time);

  /// [customName] is the free-text name used when no catalog provider is
  /// selected ("Otro").
  Future<void> submit({required String customName, String? notes}) async {
    if (state.isSubmitting) return;
    final provider = state.provider;
    final typed = customName.trim();
    if (provider == null && typed.isEmpty) {
      _events.add(const NeedsProvider());
      return;
    }
    final membership = ref.read(selectedMembershipProvider).value;
    if (membership == null) return;

    state = state.copyWith(isSubmitting: true);
    try {
      final date = state.visitDate;
      final time = state.arrivalTime;
      final trimmedNotes = notes?.trim();
      await ref
          .read(visitsRepositoryProvider)
          .createDeliveryVisit(
            residentialId: membership.residentialId,
            unitId: membership.unitId,
            name: provider?.name ?? typed,
            providerKind: state.kind,
            visitDate: date,
            arrivalTime: state.needsTime && time != null
                ? DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  )
                : null,
            notes: trimmedNotes == null || trimmedNotes.isEmpty
                ? null
                : trimmedNotes,
          );
      if (_disposed) return;
      _events.add(const VisitAuthorized());
    } catch (error) {
      if (_disposed) return;
      _events.add(AuthorizeFailed(Failure.from(error)));
    } finally {
      if (!_disposed) state = state.copyWith(isSubmitting: false);
    }
  }
}

final visitDetailsControllerProvider = NotifierProvider.autoDispose
    .family<VisitDetailsController, VisitDetailsState, VisitDetailsArgs>(
      VisitDetailsController.new,
    );

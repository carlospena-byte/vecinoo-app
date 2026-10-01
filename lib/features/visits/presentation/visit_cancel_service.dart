import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../domain/visits_repository.dart';
import 'visits_controller.dart';

/// Cancels visits and reports the outcome as a value: null on success, the
/// typed [Failure] otherwise, so screens only decide which toast to show.
class VisitCancelService {
  const VisitCancelService(this._repository);

  final VisitsRepository _repository;

  /// A FastLane invitation or a scheduled/active delivery.
  Future<Failure?> cancelVisit(String visitId) =>
      _run(() => _repository.cancelVisit(visitId));

  /// Ends a frequent visit's standing access.
  Future<Failure?> cancelFrequentVisit(String visitId) =>
      _run(() => _repository.cancelFrequentVisit(visitId));

  Future<Failure?> _run(Future<void> Function() body) async {
    try {
      await body();
      return null;
    } catch (error) {
      return Failure.from(error);
    }
  }
}

final visitCancelServiceProvider = Provider<VisitCancelService>(
  (ref) => VisitCancelService(ref.watch(visitsRepositoryProvider)),
);

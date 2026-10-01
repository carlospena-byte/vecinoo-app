import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/visits/domain/visits_repository.dart';
import 'package:gates_app/features/visits/presentation/visit_cancel_service.dart';

class _Repository implements VisitsRepository {
  final cancelled = <String>[];
  final cancelledFrequent = <String>[];
  Object? error;

  @override
  Future<void> cancelVisit(String visitId) async {
    if (error != null) throw error!;
    cancelled.add(visitId);
  }

  @override
  Future<void> cancelFrequentVisit(String visitId) async {
    if (error != null) throw error!;
    cancelledFrequent.add(visitId);
  }

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('returns null on success', () async {
    final repo = _Repository();
    final service = VisitCancelService(repo);
    expect(await service.cancelVisit('a'), isNull);
    expect(await service.cancelFrequentVisit('b'), isNull);
    expect(repo.cancelled, ['a']);
    expect(repo.cancelledFrequent, ['b']);
  });

  test('returns the typed failure', () async {
    final repo = _Repository()..error = const AuthFailure();
    final service = VisitCancelService(repo);
    expect(await service.cancelVisit('a'), isA<AuthFailure>());
    expect(await service.cancelFrequentVisit('b'), isA<AuthFailure>());
  });

  test('wraps untyped errors', () async {
    final repo = _Repository()..error = StateError('x');
    final service = VisitCancelService(repo);
    expect(await service.cancelVisit('a'), isA<UnknownFailure>());
  });
}

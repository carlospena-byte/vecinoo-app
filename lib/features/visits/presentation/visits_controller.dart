import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/supabase_visits_repository.dart';
import '../domain/access_movement.dart';
import '../domain/visit.dart';
import '../domain/visits_repository.dart';

final visitsRepositoryProvider = Provider<VisitsRepository>((ref) {
  return SupabaseVisitsRepository(ref.watch(supabaseClientProvider));
});

final visitsListProvider = StreamProvider.family<List<Visit>, String>(
  (ref, unitId) => ref.watch(visitsRepositoryProvider).watchVisits(unitId),
);

final lastMovementProvider = FutureProvider.family<AccessMovement?, String>(
  (ref, visitId) =>
      ref.watch(visitsRepositoryProvider).fetchLastMovement(visitId),
);

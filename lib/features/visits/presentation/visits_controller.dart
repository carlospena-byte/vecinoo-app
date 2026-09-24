import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/visits_repository.dart';
import '../domain/visit.dart';

final visitsRepositoryProvider = Provider<VisitsRepository>((ref) {
  return VisitsRepository(ref.watch(supabaseClientProvider));
});

final visitsListProvider = FutureProvider.family<List<Visit>, String>(
  (ref, unitId) => ref.watch(visitsRepositoryProvider).fetchVisits(unitId),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/providers_catalog_repository.dart';
import '../domain/visit.dart';

final providersCatalogRepositoryProvider = Provider<ProvidersCatalogRepository>(
  (ref) {
    return ProvidersCatalogRepository(ref.watch(supabaseClientProvider));
  },
);

typedef ProviderCatalogQuery = ({String residentialId, ProviderKind kind});

final providersCatalogProvider = FutureProvider.family(
  (Ref ref, ProviderCatalogQuery query) => ref
      .watch(providersCatalogRepositoryProvider)
      .fetchCatalog(residentialId: query.residentialId, kind: query.kind),
);

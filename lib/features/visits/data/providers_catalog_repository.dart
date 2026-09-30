import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/provider_catalog_item.dart';
import '../domain/visit.dart';

class ProvidersCatalogRepository {
  ProvidersCatalogRepository(this._client);

  final SupabaseClient _client;

  /// The platform-wide catalog plus this residential's own extras, per the
  /// "member select" RLS policy on `providers`.
  Future<List<ProviderCatalogItem>> fetchCatalog({
    required String residentialId,
    required ProviderKind kind,
  }) async {
    final rows = await _client
        .from('providers')
        .select()
        .eq('kind', kind.name)
        .eq('is_active', true)
        .or('residential_id.is.null,residential_id.eq.$residentialId')
        .order('name', ascending: true);
    return (rows as List)
        .map((row) => ProviderCatalogItem.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}

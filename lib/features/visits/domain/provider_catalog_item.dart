import 'visit.dart';

/// A row from the `providers` catalog (gates-admin migration
/// `20261014000000_providers_catalog.sql`) — a reusable delivery/vendor/
/// courier the resident can pick from instead of typing a name every time.
/// `residentialId == null` means it's a platform-wide entry.
class ProviderCatalogItem {
  const ProviderCatalogItem({
    required this.id,
    required this.residentialId,
    required this.name,
    required this.kind,
    this.logoUrl,
  });

  final String id;
  final String? residentialId;
  final String name;
  final ProviderKind kind;
  final String? logoUrl;

  factory ProviderCatalogItem.fromMap(Map<String, dynamic> map) {
    return ProviderCatalogItem(
      id: map['id'] as String,
      residentialId: map['residential_id'] as String?,
      name: map['name'] as String,
      kind: ProviderKind.values.firstWhere(
        (k) => k.name == map['kind'],
        orElse: () => ProviderKind.delivery,
      ),
      logoUrl: map['logo_url'] as String?,
    );
  }
}

/// Up to two-letter monogram for the catalog tile's identifier badge, e.g.
/// "Control de plagas" -> "CP", "DHL" -> "D".
String providerInitials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '';
  if (words.length == 1) return words.first[0].toUpperCase();
  return (words[0][0] + words[1][0]).toUpperCase();
}

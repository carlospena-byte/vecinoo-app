/// A reusable service/amenity-feature tag (WiFi, Alberca, Toallas...) from
/// the `services` catalog. `residentialId` is null for the platform-wide
/// catalog shared by every residential.
class Service {
  const Service({required this.id, required this.name, this.icon});

  final String id;
  final String name;

  /// A `@tabler/icons-react` component name (e.g. "IconWifi"), same value
  /// gates-admin lets residential admins pick from. Rendered via
  /// `serviceIconFor`.
  final String? icon;

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String?,
    );
  }
}

/// An amenity's link to one [Service], via the `amenity_services` junction
/// table. `isFeatured` rows are surfaced directly on the amenity screen;
/// the rest only appear in the "all services" sheet.
class AmenityService {
  const AmenityService({required this.service, required this.isFeatured});

  final Service service;
  final bool isFeatured;

  factory AmenityService.fromMap(Map<String, dynamic> map) {
    return AmenityService(
      service: Service.fromMap(map['services'] as Map<String, dynamic>),
      isFeatured: map['is_featured'] as bool? ?? false,
    );
  }
}

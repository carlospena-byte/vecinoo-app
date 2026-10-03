/// A unit the current user belongs to, with its residential — the
/// context amenity bookings and incident reports are filed under.
class Membership {
  const Membership({
    required this.residentialId,
    required this.residentialName,
    required this.unitId,
    required this.unitName,
    this.locationPath = const [],
  });

  final String residentialId;
  final String residentialName;
  final String unitId;
  final String unitName;

  /// Names of the levels the unit sits under, outermost first (e.g.
  /// `['Torre 1', 'Piso 1']`). Empty when the unit has no location.
  final List<String> locationPath;

  /// Full position of the unit: every level followed by the unit itself,
  /// e.g. `Torre 1 → Piso 1 → 101`.
  String get unitPath => [...locationPath, unitName].join(' → ');

  String get label => '$unitName · $residentialName';

  factory Membership.fromMap(
    Map<String, dynamic> map, {
    List<String> locationPath = const [],
  }) {
    final unit = map['units'] as Map<String, dynamic>;
    final residential = unit['residentials'] as Map<String, dynamic>;
    return Membership(
      residentialId: residential['id'] as String,
      residentialName: residential['name'] as String,
      unitId: unit['id'] as String,
      unitName: unit['name'] as String,
      locationPath: locationPath,
    );
  }
}

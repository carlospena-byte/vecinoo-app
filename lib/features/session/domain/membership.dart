/// A unit the current user belongs to, with its residential — the
/// context amenity bookings and incident reports are filed under.
class Membership {
  const Membership({
    required this.residentialId,
    required this.residentialName,
    required this.unitId,
    required this.unitName,
  });

  final String residentialId;
  final String residentialName;
  final String unitId;
  final String unitName;

  String get label => '$unitName · $residentialName';

  factory Membership.fromMap(Map<String, dynamic> map) {
    final unit = map['units'] as Map<String, dynamic>;
    final residential = unit['residentials'] as Map<String, dynamic>;
    return Membership(
      residentialId: residential['id'] as String,
      residentialName: residential['name'] as String,
      unitId: unit['id'] as String,
      unitName: unit['name'] as String,
    );
  }
}

import 'package:flutter/material.dart';

/// Maps a `services.icon` value (a `@tabler/icons-react` component name,
/// chosen from gates-admin's curated picker in `src/lib/serviceIcons.ts`)
/// to a Material icon. Covers the seeded global catalog plus other common
/// picks; anything unmapped falls back to a generic tag icon.
const Map<String, IconData> _serviceIcons = {
  'IconWifi': Icons.wifi,
  'IconPool': Icons.pool,
  'IconBarbell': Icons.fitness_center,
  'IconParking': Icons.local_parking,
  'IconLeaf': Icons.eco,
  'IconUsers': Icons.groups,
  'IconGrill': Icons.outdoor_grill,
  'IconArmchair': Icons.chair,
  'IconPicnicTable': Icons.table_restaurant,
  'IconUmbrella': Icons.beach_access,
  'IconBath': Icons.dry_cleaning,
  'IconWheelchair': Icons.accessible,
  'IconDeviceCctv': Icons.videocam,
  'IconShieldLock': Icons.shield,
  'IconElevator': Icons.elevator,
  'IconBabyCarriage': Icons.child_friendly,
  'IconDog': Icons.pets,
  'IconBallTennis': Icons.sports_tennis,
  'IconBallBasketball': Icons.sports_basketball,
  'IconSoccerField': Icons.sports_soccer,
  'IconMovie': Icons.movie,
  'IconDice': Icons.casino,
  'IconYoga': Icons.self_improvement,
  'IconBike': Icons.pedal_bike,
  'IconWashMachine': Icons.local_laundry_service,
  'IconToolsKitchen2': Icons.kitchen,
  'IconAirConditioning': Icons.ac_unit,
  'IconDesk': Icons.desk,
  'IconBuildingWarehouse': Icons.warehouse,
  'IconSun': Icons.wb_sunny,
  'IconWind': Icons.air,
  'IconToilet': Icons.wc,
};

IconData serviceIconFor(String? iconName) {
  if (iconName == null) return Icons.label_outline;
  return _serviceIcons[iconName] ?? Icons.label_outline;
}

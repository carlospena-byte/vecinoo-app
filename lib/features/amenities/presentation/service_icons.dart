import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

/// Maps a `services.icon` value (a `@tabler/icons-react` component name,
/// chosen from gates-admin's curated picker in `src/lib/serviceIcons.ts`)
/// to a Tabler icon. Covers the seeded global catalog plus other common
/// picks; anything unmapped falls back to a generic tag icon.
const Map<String, IconData> _serviceIcons = {
  'IconWifi': TablerIcons.wifi,
  'IconPool': TablerIcons.pool,
  'IconBarbell': TablerIcons.barbell,
  'IconParking': TablerIcons.parking,
  'IconLeaf': TablerIcons.leaf,
  'IconUsers': TablerIcons.users,
  'IconGrill': TablerIcons.grill,
  'IconArmchair': TablerIcons.armchair,
  'IconPicnicTable': TablerIcons.picnicTable,
  'IconUmbrella': TablerIcons.umbrella,
  'IconBath': TablerIcons.bath,
  'IconWheelchair': TablerIcons.wheelchair,
  'IconDeviceCctv': TablerIcons.deviceCctv,
  'IconShieldLock': TablerIcons.shieldLock,
  'IconElevator': TablerIcons.elevator,
  'IconBabyCarriage': TablerIcons.babyCarriage,
  'IconDog': TablerIcons.dog,
  'IconBallTennis': TablerIcons.ballTennis,
  'IconBallBasketball': TablerIcons.ballBasketball,
  'IconSoccerField': TablerIcons.soccerField,
  'IconMovie': TablerIcons.movie,
  'IconDice': TablerIcons.dice,
  'IconYoga': TablerIcons.yoga,
  'IconBike': TablerIcons.bike,
  'IconWashMachine': TablerIcons.washMachine,
  'IconToolsKitchen2': TablerIcons.toolsKitchen2,
  'IconAirConditioning': TablerIcons.airConditioning,
  'IconDesk': TablerIcons.desk,
  'IconBuildingWarehouse': TablerIcons.buildingWarehouse,
  'IconSun': TablerIcons.sun,
  'IconWind': TablerIcons.wind,
  'IconToilet': TablerIcons.toiletPaper,
};

IconData serviceIconFor(String? iconName) {
  if (iconName == null) return TablerIcons.tag;
  return _serviceIcons[iconName] ?? TablerIcons.tag;
}

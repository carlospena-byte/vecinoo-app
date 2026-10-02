import 'package:shared_preferences/shared_preferences.dart';

import '../domain/bulletins_repository.dart';

/// Read marks kept on the device (SharedPreferences), one list per
/// residential.
class LocalBulletinReadsRepository implements BulletinReadsRepository {
  static String _key(String residentialId) => 'bulletins_read_$residentialId';

  @override
  Future<Set<String>> readIds(String residentialId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key(residentialId)) ?? const []).toSet();
  }

  @override
  Future<void> markRead(String residentialId, String bulletinId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = {...?prefs.getStringList(_key(residentialId)), bulletinId};
    await prefs.setStringList(_key(residentialId), ids.toList());
  }
}

/// Maintenance switch set by a platform admin in gates-admin
/// (`app_config`). Title/message are optional: the screen has defaults.
class MaintenanceInfo {
  const MaintenanceInfo({required this.enabled, this.title, this.message});

  factory MaintenanceInfo.fromMap(Map<String, dynamic> map) => MaintenanceInfo(
    enabled: map['enabled'] == true,
    title: _text(map['title']),
    message: _text(map['message']),
  );

  final bool enabled;
  final String? title;
  final String? message;
}

/// A newer release for this device's store (`app_versions`). [isForced]
/// means the app can't be used until the user updates.
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.isForced,
    required this.storeUrl,
    this.title,
    this.message,
  });

  factory UpdateInfo.fromMap(Map<String, dynamic> map) => UpdateInfo(
    version: map['version'] as String,
    isForced: map['is_forced'] == true,
    storeUrl: map['store_url'] as String,
    title: _text(map['title']),
    message: _text(map['message']),
  );

  final String version;
  final bool isForced;
  final String storeUrl;
  final String? title;
  final String? message;
}

/// What the backend says about the running app: under maintenance and/or a
/// newer version is available.
class AppStatus {
  const AppStatus({required this.maintenance, this.update});

  /// Result of `get_app_status`:
  /// `{ maintenance: {enabled,title,message}, update: null | {...} }`.
  factory AppStatus.fromMap(Map<String, dynamic> map) {
    final maintenance = map['maintenance'];
    final update = map['update'];
    return AppStatus(
      maintenance: maintenance is Map<String, dynamic>
          ? MaintenanceInfo.fromMap(maintenance)
          : const MaintenanceInfo(enabled: false),
      update: update is Map<String, dynamic>
          ? UpdateInfo.fromMap(update)
          : null,
    );
  }

  static const operational = AppStatus(
    maintenance: MaintenanceInfo(enabled: false),
  );

  final MaintenanceInfo maintenance;
  final UpdateInfo? update;
}

String? _text(Object? value) {
  final text = value is String ? value.trim() : null;
  return text == null || text.isEmpty ? null : text;
}

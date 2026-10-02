import 'app_status.dart';

/// Reads the platform-wide app status. Implementations throw `Failure`s
/// (see core/error/failure.dart). Needs no session: the maintenance and
/// update screens must show to signed-out users too.
abstract interface class AppStatusRepository {
  /// [platform] is `ios` or `android`; [version] the installed version
  /// ("1.2.0"). Releases are per platform, so they never cross.
  Future<AppStatus> fetch({required String platform, required String version});
}

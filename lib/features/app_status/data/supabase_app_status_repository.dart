import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../domain/app_status.dart';
import '../domain/app_status_repository.dart';

/// Calls the `get_app_status` RPC (gates-admin migration
/// `20261112000000_app_settings.sql`), executable by anon and authenticated.
class SupabaseAppStatusRepository implements AppStatusRepository {
  SupabaseAppStatusRepository(this._client);

  final SupabaseClient _client;

  /// A slow or dead connection must not hold the app on a blank screen.
  static const _timeout = Duration(seconds: 6);

  @override
  Future<AppStatus> fetch({
    required String platform,
    required String version,
  }) => guardFailure(() async {
    final result = await _client
        .rpc(
          'get_app_status',
          params: {'p_platform': platform, 'p_version': version},
        )
        .timeout(_timeout);
    return AppStatus.fromMap(result as Map<String, dynamic>);
  });
}

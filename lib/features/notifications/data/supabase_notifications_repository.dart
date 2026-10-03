import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../domain/notifications_repository.dart';
import '../domain/user_notification.dart';

/// Supabase-backed [NotificationsRepository]. RLS limits every query to the
/// signed-in user's own rows; the explicit `user_id` filters keep the intent
/// visible and scope the realtime stream.
class SupabaseNotificationsRepository implements NotificationsRepository {
  SupabaseNotificationsRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'user_notifications';

  /// The unread badge only looks at this many of the newest rows.
  static const _badgeWindow = 100;

  String get _userId => _client.auth.currentUser?.id ?? '';

  @override
  Future<List<UserNotification>> fetchNotifications({
    required int limit,
    int offset = 0,
  }) => guardFailure(() async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (rows as List)
        .map((row) => UserNotification.fromMap(row as Map<String, dynamic>))
        .toList();
  });

  @override
  Future<void> markRead(String notificationId) => guardFailure(() async {
    await _client
        .from(_table)
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', notificationId)
        .isFilter('read_at', null);
  });

  @override
  Future<void> markAllRead() => guardFailure(() async {
    await _client
        .from(_table)
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', _userId)
        .isFilter('read_at', null);
  });

  @override
  Stream<int> watchUnreadCount() => _client
      .from(_table)
      .stream(primaryKey: ['id'])
      .eq('user_id', _userId)
      .order('created_at', ascending: false)
      .limit(_badgeWindow)
      .map((rows) => rows.where((row) => row['read_at'] == null).length);
}

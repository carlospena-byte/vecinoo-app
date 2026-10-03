import 'user_notification.dart';

/// What the notifications inbox needs from storage. Implementations throw
/// `Failure`s (see core/error/failure.dart), never raw backend exceptions.
abstract interface class NotificationsRepository {
  /// One page of the signed-in resident's notifications, newest first. A
  /// page shorter than [limit] is the last one.
  Future<List<UserNotification>> fetchNotifications({
    required int limit,
    int offset = 0,
  });

  Future<void> markRead(String notificationId);

  Future<void> markAllRead();

  /// Live count of unread notifications (capped at the most recent ones),
  /// re-emitted as notifications arrive or are read.
  Stream<int> watchUnreadCount();
}

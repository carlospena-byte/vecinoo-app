import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/paging/paged_notifier.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../data/supabase_notifications_repository.dart';
import '../domain/notifications_repository.dart';
import '../domain/user_notification.dart';

const notificationsPageSize = 20;

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return SupabaseNotificationsRepository(ref.watch(supabaseClientProvider));
});

/// Unread notifications, live; drives the Home bell badge.
final unreadNotificationsCountProvider = StreamProvider<int>(
  (ref) => ref.watch(notificationsRepositoryProvider).watchUnreadCount(),
);

/// Pages through the inbox [notificationsPageSize] at a time.
class NotificationsPagingController extends PagedNotifier<UserNotification> {
  @override
  int get pageSize => notificationsPageSize;

  @override
  Future<List<UserNotification>> fetchPage({
    required int offset,
    required int limit,
  }) => ref
      .read(notificationsRepositoryProvider)
      .fetchNotifications(limit: limit, offset: offset);

  /// Marks one as read: instantly in the list, then in storage. A failed
  /// write is dropped; the badge stream reconciles on the next change.
  Future<void> markRead(String id) async {
    final now = DateTime.now();
    state = state.copyWith(
      items: [for (final n in state.items) n.id == id ? n.markedRead(now) : n],
    );
    try {
      await ref.read(notificationsRepositoryProvider).markRead(id);
    } on Failure {
      // Ignored on purpose, see above.
    }
  }

  /// Marks everything as read. Returns false when storage rejected it, in
  /// which case the list is left as it was.
  Future<bool> markAllRead() async {
    try {
      await ref.read(notificationsRepositoryProvider).markAllRead();
    } on Failure {
      return false;
    }
    final now = DateTime.now();
    state = state.copyWith(
      items: [for (final n in state.items) n.markedRead(now)],
    );
    return true;
  }
}

final notificationsPagingProvider =
    NotifierProvider.autoDispose<
      NotificationsPagingController,
      PagedState<UserNotification>
    >(NotificationsPagingController.new);

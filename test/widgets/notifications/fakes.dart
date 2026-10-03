import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:gates_app/features/notifications/domain/notifications_repository.dart';
import 'package:gates_app/features/notifications/domain/user_notification.dart';
import 'package:gates_app/features/notifications/presentation/notifications_controller.dart';

UserNotification makeNotification({
  String id = 'n1',
  String type = 'bulletin',
  String title = 'Nuevo boletín',
  String body = 'Corte de agua',
  Map<String, dynamic>? data,
  DateTime? createdAt,
  DateTime? readAt,
}) => UserNotification(
  id: id,
  type: type,
  title: title,
  body: body,
  data: data ?? {'type': type, 'bulletin_id': 'b1'},
  createdAt: createdAt ?? DateTime.now(),
  readAt: readAt,
);

class FakeNotificationsRepository implements NotificationsRepository {
  List<UserNotification> notifications = [];
  Object? listError;
  Object? markError;
  final offsets = <int>[];
  final markedRead = <String>[];
  int markAllCalls = 0;
  final unread = StreamController<int>.broadcast();

  @override
  Future<List<UserNotification>> fetchNotifications({
    required int limit,
    int offset = 0,
  }) async {
    offsets.add(offset);
    if (listError != null) throw listError!;
    return notifications.skip(offset).take(limit).toList();
  }

  @override
  Future<void> markRead(String notificationId) async {
    if (markError != null) throw markError!;
    markedRead.add(notificationId);
  }

  @override
  Future<void> markAllRead() async {
    markAllCalls++;
    if (markError != null) throw markError!;
  }

  @override
  Stream<int> watchUnreadCount() => unread.stream;
}

List<Override> notificationOverrides([FakeNotificationsRepository? repo]) => [
  notificationsRepositoryProvider.overrideWithValue(
    repo ?? FakeNotificationsRepository(),
  ),
];

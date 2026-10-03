/// One entry of the resident's notification inbox. [data] is the push
/// payload (`type`, `bulletin_id`, `route`, ...), so a tap resolves its
/// destination the same way a tapped push does.
class UserNotification {
  const UserNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  UserNotification markedRead(DateTime at) => UserNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    data: data,
    createdAt: createdAt,
    readAt: readAt ?? at,
  );

  factory UserNotification.fromMap(Map<String, dynamic> map) {
    final readAt = map['read_at'] as String?;
    return UserNotification(
      id: map['id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      data: Map<String, dynamic>.from(map['data'] as Map? ?? const {}),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      readAt: readAt == null ? null : DateTime.parse(readAt).toLocal(),
    );
  }
}

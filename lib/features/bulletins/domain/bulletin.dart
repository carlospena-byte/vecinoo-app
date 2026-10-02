enum BulletinAttachmentKind { image, pdf }

BulletinAttachmentKind? attachmentKindFromString(String value) {
  switch (value) {
    case 'image':
      return BulletinAttachmentKind.image;
    case 'pdf':
      return BulletinAttachmentKind.pdf;
    default:
      return null;
  }
}

class Bulletin {
  const Bulletin({
    required this.id,
    required this.title,
    this.description,
    required this.publishedAt,
    this.imageCount = 0,
    this.pdfCount = 0,
  });

  final String id;
  final String title;

  /// HTML from the admin's rich text editor (p, strong, em, ul/ol/li, a).
  final String? description;
  final DateTime publishedAt;
  final int imageCount;
  final int pdfCount;

  /// Description as plain text, for list previews.
  String get excerpt => htmlToPlainText(description ?? '');

  factory Bulletin.fromMap(Map<String, dynamic> map) {
    final kinds = [
      for (final row in (map['bulletin_attachments'] as List? ?? const []))
        (row as Map<String, dynamic>)['kind'] as String?,
    ];
    return Bulletin(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      // published_at is stamped by a trigger when the bulletin is published;
      // created_at only guards against a row that predates it.
      publishedAt: DateTime.parse(
        (map['published_at'] ?? map['created_at']) as String,
      ).toLocal(),
      imageCount: kinds.where((k) => k == 'image').length,
      pdfCount: kinds.where((k) => k == 'pdf').length,
    );
  }
}

class BulletinAttachment {
  const BulletinAttachment({
    required this.id,
    required this.kind,
    required this.fileName,
    this.fileSize,
    required this.url,
  });

  final String id;
  final BulletinAttachmentKind kind;
  final String fileName;
  final int? fileSize;

  /// Short-lived signed URL (the bucket is private).
  final String url;
}

/// Strips tags and collapses whitespace; enough for a one-line preview of
/// the editor's small HTML subset.
String htmlToPlainText(String html) {
  return html
      .replaceAll(RegExp(r'</(p|li|ul|ol)>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

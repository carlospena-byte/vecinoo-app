import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/notifications/push_navigation.dart';
import 'package:gates_app/features/bulletins/domain/bulletin.dart';

Map<String, dynamic> _map({Map<String, dynamic>? extra}) => {
  'id': 'b1',
  'title': 'Corte de agua',
  'created_at': '2026-03-01T10:00:00Z',
  'published_at': '2026-03-02T12:00:00Z',
  ...?extra,
};

void main() {
  group('Bulletin.fromMap', () {
    test('reads the published date and counts attachments by kind', () {
      final bulletin = Bulletin.fromMap(
        _map(
          extra: {
            'description': '<p>Mañana</p>',
            'bulletin_attachments': [
              {'kind': 'image'},
              {'kind': 'image'},
              {'kind': 'pdf'},
            ],
          },
        ),
      );
      expect(bulletin.id, 'b1');
      expect(bulletin.publishedAt, DateTime.utc(2026, 3, 2, 12).toLocal());
      expect(bulletin.imageCount, 2);
      expect(bulletin.pdfCount, 1);
    });

    test('falls back to created_at and tolerates missing attachments', () {
      final bulletin = Bulletin.fromMap(_map(extra: {'published_at': null}));
      expect(bulletin.publishedAt, DateTime.utc(2026, 3, 1, 10).toLocal());
      expect(bulletin.imageCount, 0);
      expect(bulletin.pdfCount, 0);
      expect(bulletin.description, isNull);
    });
  });

  group('htmlToPlainText', () {
    test('strips tags, decodes entities and collapses whitespace', () {
      expect(
        htmlToPlainText(
          '<p>Hola <strong>vecinos</strong>&nbsp;&amp; amigos</p>'
          '<ul><li>Uno</li><li>Dos</li></ul>',
        ),
        'Hola vecinos & amigos Uno Dos',
      );
    });

    test('empty input gives an empty excerpt', () {
      expect(htmlToPlainText(''), '');
      expect(htmlToPlainText('<p></p>'), '');
    });
  });

  test('attachmentKindFromString maps known kinds and ignores others', () {
    expect(attachmentKindFromString('image'), BulletinAttachmentKind.image);
    expect(attachmentKindFromString('pdf'), BulletinAttachmentKind.pdf);
    expect(attachmentKindFromString('video'), isNull);
  });

  group('notificationRoute', () {
    test('bulletin pushes open that bulletin', () {
      expect(
        notificationRoute({'type': 'bulletin', 'bulletin_id': 'abc-123'}),
        '/bulletins/abc-123',
      );
    });

    test('deeplink pushes open allowed routes only', () {
      expect(
        notificationRoute({'type': 'deeplink', 'route': '/billing'}),
        '/billing',
      );
      expect(
        notificationRoute({'type': 'deeplink', 'route': '/bulletins/abc-1'}),
        '/bulletins/abc-1',
      );
      expect(notificationRoute({'type': 'deeplink'}), isNull);
      expect(
        notificationRoute({'type': 'deeplink', 'route': '/login'}),
        isNull,
      );
      expect(
        notificationRoute({'type': 'deeplink', 'route': '/bulletins/a/b'}),
        isNull,
      );
    });

    test('unknown or incomplete payloads have no destination', () {
      expect(notificationRoute({}), isNull);
      expect(notificationRoute({'type': 'bulletin'}), isNull);
      expect(
        notificationRoute({'type': 'bulletin', 'bulletin_id': ''}),
        isNull,
      );
      expect(notificationRoute({'type': 'other', 'bulletin_id': 'x'}), isNull);
    });
  });
}

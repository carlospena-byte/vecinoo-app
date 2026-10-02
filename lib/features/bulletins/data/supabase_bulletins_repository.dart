import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../domain/bulletin.dart';
import '../domain/bulletins_repository.dart';

/// Supabase-backed [BulletinsRepository]; every call surfaces errors as
/// `Failure`s. RLS already hides drafts from residents; the explicit
/// `status` filter keeps the intent visible (and covers admin accounts,
/// who can see drafts, using the app).
class SupabaseBulletinsRepository implements BulletinsRepository {
  SupabaseBulletinsRepository(this._client);

  final SupabaseClient _client;

  static const _bucket = 'bulletin-attachments';

  @override
  Future<List<Bulletin>> fetchBulletins(
    String residentialId, {
    required int limit,
    int offset = 0,
  }) => guardFailure(() async {
    final rows = await _client
        .from('bulletins')
        .select('*, bulletin_attachments(kind)')
        .eq('residential_id', residentialId)
        .eq('status', 'published')
        .order('published_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (rows as List)
        .map((row) => Bulletin.fromMap(row as Map<String, dynamic>))
        .toList();
  });

  @override
  Future<Bulletin> fetchBulletin(String bulletinId) => guardFailure(() async {
    final row = await _client
        .from('bulletins')
        .select('*, bulletin_attachments(kind)')
        .eq('id', bulletinId)
        .eq('status', 'published')
        .single();
    return Bulletin.fromMap(row);
  });

  @override
  Future<List<BulletinAttachment>> fetchAttachments(String bulletinId) =>
      guardFailure(() async {
        final rows = await _client
            .from('bulletin_attachments')
            .select('id, kind, storage_path, file_name, file_size, sort_order')
            .eq('bulletin_id', bulletinId)
            .order('sort_order', ascending: true);
        final list = (rows as List).cast<Map<String, dynamic>>();
        if (list.isEmpty) return const [];

        final signed = await _client.storage
            .from(_bucket)
            .createSignedUrlsResult([
              for (final r in list) r['storage_path'] as String,
            ], 60 * 60);
        final urls = {
          for (final result in signed)
            if (result is SignedUrlSuccess) result.path: result.signedUrl,
        };

        final attachments = <BulletinAttachment>[
          for (final r in list)
            if (urls[r['storage_path']] != null &&
                attachmentKindFromString(r['kind'] as String) != null)
              BulletinAttachment(
                id: r['id'] as String,
                kind: attachmentKindFromString(r['kind'] as String)!,
                fileName: r['file_name'] as String,
                fileSize: (r['file_size'] as num?)?.toInt(),
                url: urls[r['storage_path']]!,
              ),
        ];
        // Stable sort: images before PDFs, admin order kept within each.
        return [
          ...attachments.where((a) => a.kind == BulletinAttachmentKind.image),
          ...attachments.where((a) => a.kind == BulletinAttachmentKind.pdf),
        ];
      });
}

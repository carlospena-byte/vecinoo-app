import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/paging/paged_notifier.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../data/local_bulletin_reads_repository.dart';
import '../data/supabase_bulletins_repository.dart';
import '../domain/bulletin.dart';
import '../domain/bulletins_repository.dart';

/// Bulletins fetched per request (and the most the home card needs).
const bulletinsPageSize = PagedNotifier.defaultPageSize;

final bulletinsRepositoryProvider = Provider<BulletinsRepository>((ref) {
  return SupabaseBulletinsRepository(ref.watch(supabaseClientProvider));
});

final bulletinReadsRepositoryProvider = Provider<BulletinReadsRepository>(
  (ref) => LocalBulletinReadsRepository(),
);

/// Latest page of bulletins; the Home card shows the first one.
final bulletinsListProvider = FutureProvider.family<List<Bulletin>, String>(
  (ref, residentialId) => ref
      .watch(bulletinsRepositoryProvider)
      .fetchBulletins(residentialId, limit: bulletinsPageSize),
);

final bulletinDetailProvider = FutureProvider.family<Bulletin, String>(
  (ref, bulletinId) =>
      ref.watch(bulletinsRepositoryProvider).fetchBulletin(bulletinId),
);

final bulletinAttachmentsProvider =
    FutureProvider.family<List<BulletinAttachment>, String>(
      (ref, bulletinId) =>
          ref.watch(bulletinsRepositoryProvider).fetchAttachments(bulletinId),
    );

/// Ids of the bulletins already opened in this residential.
class BulletinReadIdsController extends Notifier<Set<String>> {
  BulletinReadIdsController(this.residentialId);

  final String residentialId;

  @override
  Set<String> build() {
    ref
        .read(bulletinReadsRepositoryProvider)
        .readIds(residentialId)
        .then((ids) => state = {...state, ...ids});
    return const {};
  }

  Future<void> markRead(String bulletinId) async {
    if (state.contains(bulletinId)) return;
    state = {...state, bulletinId};
    await ref
        .read(bulletinReadsRepositoryProvider)
        .markRead(residentialId, bulletinId);
  }
}

final bulletinReadIdsProvider =
    NotifierProvider.family<BulletinReadIdsController, Set<String>, String>(
      BulletinReadIdsController.new,
    );

/// Pages through the published bulletins [bulletinsPageSize] at a time.
class BulletinsPagingController extends PagedNotifier<Bulletin> {
  BulletinsPagingController(this.residentialId);

  final String residentialId;

  @override
  int get pageSize => bulletinsPageSize;

  @override
  Future<List<Bulletin>> fetchPage({required int offset, required int limit}) =>
      ref
          .read(bulletinsRepositoryProvider)
          .fetchBulletins(residentialId, limit: limit, offset: offset);
}

final bulletinsPagingProvider = NotifierProvider.autoDispose
    .family<BulletinsPagingController, PagedState<Bulletin>, String>(
      BulletinsPagingController.new,
    );

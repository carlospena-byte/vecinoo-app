import 'bulletin.dart';

/// What the bulletins feature needs from storage. Implementations throw
/// `Failure`s (see core/error/failure.dart), never raw backend exceptions.
abstract interface class BulletinsRepository {
  /// One page of the published bulletins of this residential, newest
  /// first. A page shorter than [limit] is the last one.
  Future<List<Bulletin>> fetchBulletins(
    String residentialId, {
    required int limit,
    int offset = 0,
  });

  Future<Bulletin> fetchBulletin(String bulletinId);

  /// Images first, then PDFs, each in the order the admin set.
  Future<List<BulletinAttachment>> fetchAttachments(String bulletinId);
}

/// Which bulletins this device's resident has already opened. Scoped per
/// residential so switching communities keeps separate histories.
abstract interface class BulletinReadsRepository {
  Future<Set<String>> readIds(String residentialId);

  Future<void> markRead(String residentialId, String bulletinId);
}

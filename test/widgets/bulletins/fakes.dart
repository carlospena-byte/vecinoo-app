import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:gates_app/features/bulletins/domain/bulletin.dart';
import 'package:gates_app/features/bulletins/domain/bulletins_repository.dart';
import 'package:gates_app/features/bulletins/presentation/bulletins_controller.dart';

import '../../helpers/pump_app.dart';

Bulletin makeBulletin({
  String id = 'b1',
  String title = 'Corte de agua',
  String? description,
  DateTime? publishedAt,
  int imageCount = 0,
  int pdfCount = 0,
}) => Bulletin(
  id: id,
  title: title,
  description: description,
  publishedAt: publishedAt ?? DateTime(2026, 3, 2, 12),
  imageCount: imageCount,
  pdfCount: pdfCount,
);

class FakeBulletinsRepository implements BulletinsRepository {
  List<Bulletin> bulletins = [];
  Object? listError;
  Bulletin? detail;
  Object? detailError;
  List<BulletinAttachment> attachments = [];
  int listFetches = 0;
  final offsets = <int>[];

  @override
  Future<List<Bulletin>> fetchBulletins(
    String residentialId, {
    required int limit,
    int offset = 0,
  }) async {
    listFetches++;
    offsets.add(offset);
    if (listError != null) throw listError!;
    return bulletins.skip(offset).take(limit).toList();
  }

  @override
  Future<Bulletin> fetchBulletin(String bulletinId) async {
    if (detailError != null) throw detailError!;
    return detail!;
  }

  @override
  Future<List<BulletinAttachment>> fetchAttachments(String bulletinId) async =>
      attachments;
}

class FakeBulletinReadsRepository implements BulletinReadsRepository {
  FakeBulletinReadsRepository([Set<String> read = const {}]) : read = {...read};

  final Set<String> read;

  @override
  Future<Set<String>> readIds(String residentialId) async => {...read};

  @override
  Future<void> markRead(String residentialId, String bulletinId) async {
    read.add(bulletinId);
  }
}

List<Override> bulletinOverrides(
  FakeBulletinsRepository repo, [
  FakeBulletinReadsRepository? reads,
]) => [
  bulletinsRepositoryProvider.overrideWithValue(repo),
  bulletinReadsRepositoryProvider.overrideWithValue(
    reads ?? FakeBulletinReadsRepository(),
  ),
  ...membershipOverrides(),
];

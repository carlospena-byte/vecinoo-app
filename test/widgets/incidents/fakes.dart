import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart' show addTearDown;

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:gates_app/features/auth/domain/auth_repository.dart';
import 'package:gates_app/features/auth/presentation/auth_controller.dart';
import 'package:gates_app/features/incidents/domain/incident.dart';
import 'package:gates_app/features/incidents/domain/incidents_repository.dart';
import 'package:gates_app/features/incidents/presentation/incidents_controller.dart';
import 'package:gates_app/features/incidents/presentation/photo_picker.dart';
import 'package:image_picker/image_picker.dart' show XFile;

import '../../helpers/pump_app.dart';

Incident makeIncident({
  String id = 'i1',
  String title = 'Fuga en el pasillo',
  String? description,
  IncidentStatus status = IncidentStatus.newIncident,
  String? typeId,
  String? typeName,
  String? reportedBy = 'u1',
  DateTime? createdAt,
}) => Incident(
  id: id,
  title: title,
  description: description,
  incidentTypeId: typeId,
  incidentTypeName: typeName,
  priority: IncidentPriority.medium,
  status: status,
  createdAt: createdAt ?? DateTime(2026, 3, 1, 10, 30),
  reportedBy: reportedBy,
);

class FakeIncidentsRepository implements IncidentsRepository {
  List<Incident> incidents = [];
  Object? listError;
  Incident? detail;
  Object? detailError;
  List<IncidentAttachment> attachments = [];
  List<IncidentType> types = const [
    IncidentType(id: 't1', name: 'Mantenimiento'),
    IncidentType(id: 't2', name: 'Seguridad'),
  ];
  Object? cancelError;
  Object? createError;
  Object? updateError;
  int uploadFailuresLeft = 0;

  final calls = <String>[];
  int listFetches = 0;

  @override
  Future<List<Incident>> fetchIncidents(String residentialId) async {
    listFetches++;
    if (listError != null) throw listError!;
    return incidents;
  }

  @override
  Future<Incident> fetchIncident(String incidentId) async {
    if (detailError != null) throw detailError!;
    return detail!;
  }

  @override
  Future<List<IncidentAttachment>> fetchAttachments(String incidentId) async =>
      attachments;

  @override
  Future<List<IncidentType>> fetchIncidentTypes(String residentialId) async =>
      types;

  @override
  Future<String> createIncident({
    required String residentialId,
    required String unitId,
    required String title,
    String? description,
    String? incidentTypeId,
    String? location,
    IncidentPriority priority = IncidentPriority.medium,
  }) async {
    calls.add('create:$title|$description|$incidentTypeId');
    if (createError != null) throw createError!;
    return 'new-1';
  }

  @override
  Future<void> updateIncident({
    required String incidentId,
    required String title,
    String? description,
    String? incidentTypeId,
  }) async {
    calls.add('update:$incidentId:$title|$description|$incidentTypeId');
    if (updateError != null) throw updateError!;
  }

  @override
  Future<void> uploadPhoto({
    required String residentialId,
    required String incidentId,
    required Uint8List bytes,
    required String extension,
  }) async {
    calls.add('upload:$incidentId:$extension');
    if (uploadFailuresLeft > 0) {
      uploadFailuresLeft--;
      throw Exception('upload failed');
    }
  }

  @override
  Future<void> deleteAttachment(IncidentAttachment attachment) async {
    calls.add('delete:${attachment.id}');
  }

  @override
  Future<void> cancelIncident(String incidentId) async {
    calls.add('cancel:$incidentId');
    if (cancelError != null) throw cancelError!;
  }
}

class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker([this.count = 1]);
  int count;
  Object? error;
  final sources = <PhotoSource>[];

  @override
  Future<List<XFile>> pick(PhotoSource source) async {
    sources.add(source);
    if (error != null) throw error!;
    return [
      for (var i = 0; i < count; i++)
        XFile.fromData(Uint8List.fromList([1, 2, 3]), path: 'foto$i.png'),
    ];
  }
}

class _FakeAuthRepo implements AuthRepository {
  _FakeAuthRepo(this.currentUser);
  @override
  final SignedInUser? currentUser;
  @override
  Stream<SignedInUser?> get userChanges => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

List<Override> incidentOverrides(
  FakeIncidentsRepository repo, {
  FakePhotoPicker? picker,
  String? userId = 'u1',
}) => [
  incidentsRepositoryProvider.overrideWithValue(repo),
  if (picker != null) photoPickerProvider.overrideWithValue(picker),
  authRepositoryProvider.overrideWithValue(
    _FakeAuthRepo(userId == null ? null : SignedInUser(id: userId)),
  ),
  ...membershipOverrides(),
];

/// Photo thumbnails load from files/URLs that do not exist in tests; swallow
/// just those image errors so layout assertions can run.
void ignoreImageErrors() {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.exceptionAsString();
    if (text.contains('HTTP request failed') ||
        text.contains('PathNotFound') ||
        text.contains('Unable to load asset') ||
        details.library == 'image resource service') {
      return;
    }
    previous?.call(details);
  };
  addTearDown(() => FlutterError.onError = previous);
}

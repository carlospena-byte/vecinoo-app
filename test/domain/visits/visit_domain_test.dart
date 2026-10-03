import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/visits/domain/access_movement.dart';
import 'package:gates_app/features/visits/domain/provider_catalog_item.dart';
import 'package:gates_app/features/visits/domain/visit.dart';
import 'package:gates_app/features/visits/presentation/fastlane_link.dart';
import 'package:gates_app/features/visits/presentation/frequent_visit_formatters.dart';
import 'package:gates_app/features/visits/presentation/visit_date_formatters.dart';
import 'package:gates_app/features/visits/presentation/visit_failure_text.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';
import 'package:intl/date_symbol_data_local.dart';

Map<String, dynamic> _row([Map<String, dynamic> extra = const {}]) => {
  'id': 'v1',
  'unit_id': 'u1',
  'status': 'scheduled',
  'visit_type': 'delivery',
  'valid_from': '2026-09-30T14:00:00Z',
  'valid_until': '2026-09-30T23:59:00Z',
  'created_at': '2026-09-29T10:00:00Z',
  ...extra,
};

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  final l10n = AppLocalizationsEs();

  group('Visit.fromMap', () {
    test('minimal row uses defaults', () {
      final v = Visit.fromMap(_row());
      expect(v.id, 'v1');
      expect(v.unitId, 'u1');
      expect(v.name, isNull);
      expect(v.status, VisitStatus.scheduled);
      expect(v.visitType, VisitType.delivery);
      expect(v.visitorRole, isNull);
      expect(v.providerKind, isNull);
      expect(v.recurrence, isNull);
      expect(v.recurrenceDays, isNull);
      expect(v.scheduleType, ScheduleType.allDay);
      expect(v.scheduleStart, isNull);
      expect(v.scheduleBlocks, isNull);
      expect(v.hasVehicle, isFalse);
      expect(v.notifyOnArrival, isFalse);
      expect(v.validFrom.isUtc, isFalse);
      expect(v.validFrom.toUtc(), DateTime.utc(2026, 9, 30, 14));
    });

    test('full frequent row parses every field', () {
      final v = Visit.fromMap(
        _row({
          'name': 'María',
          'phone': '+50499998888',
          'plate': 'HAB1234',
          'status': 'inside',
          'visit_type': 'frequent',
          'visitor_role': 'entrenador',
          'provider_kind': 'paqueteria',
          'recurrence': 'mon_sat',
          'recurrence_days': ['mon', 'tue'],
          'schedule_type': 'custom',
          'schedule_start': '08:00:00',
          'schedule_end': '22:30:00',
          'schedule_blocks': [
            {
              'days': ['mon', 'wed'],
              'start': '08:00:00',
              'end': '10:00:00',
            },
          ],
          'has_vehicle': true,
          'notify_on_arrival': true,
          'id_photo_path': 'r/x.jpg',
          'notes': 'n',
          'access_code': 'ABC',
        }),
      );
      expect(v.status, VisitStatus.inside);
      expect(v.visitType, VisitType.frequent);
      expect(v.visitorRole, VisitorRole.entrenador);
      expect(v.providerKind, ProviderKind.paqueteria);
      expect(v.recurrence, Recurrence.monSat);
      expect(v.recurrenceDays, ['mon', 'tue']);
      expect(v.scheduleType, ScheduleType.custom);
      expect(v.scheduleStart, const TimeOfDay(hour: 8, minute: 0));
      expect(v.scheduleEnd, const TimeOfDay(hour: 22, minute: 30));
      expect(v.scheduleBlocks!.single.days, {'mon', 'wed'});
      expect(v.hasVehicle, isTrue);
      expect(v.notifyOnArrival, isTrue);
      expect(v.idPhotoPath, 'r/x.jpg');
      expect(v.notes, 'n');
      expect(v.accessCode, 'ABC');
      expect(v.phone, '+50499998888');
      expect(v.plate, 'HAB1234');
    });

    test('unknown enum strings fall back to safe defaults', () {
      final v = Visit.fromMap(
        _row({
          'status': 'weird',
          'visit_type': 'weird',
          'visitor_role': 'weird',
          'provider_kind': 'weird',
          'recurrence': 'weird',
        }),
      );
      expect(v.status, VisitStatus.scheduled);
      expect(v.visitType, VisitType.frequent);
      expect(v.visitorRole, VisitorRole.visitante);
      expect(v.providerKind, ProviderKind.delivery);
      expect(v.recurrence, Recurrence.daily);
    });
  });

  group('enums and converters', () {
    test('visitStatusFromString covers every db value', () {
      const map = {
        'pending_registration': VisitStatus.pendingRegistration,
        'scheduled': VisitStatus.scheduled,
        'active': VisitStatus.active,
        'inside': VisitStatus.inside,
        'completed': VisitStatus.completed,
        'cancelled': VisitStatus.cancelled,
        'rejected': VisitStatus.rejected,
        'expired': VisitStatus.expired,
      };
      map.forEach((k, v) => expect(visitStatusFromString(k), v));
      expect(visitStatusFromString(''), VisitStatus.scheduled);
    });

    test('labels exist and are non-empty for every enum value', () {
      for (final s in VisitStatus.values) {
        expect(visitStatusLabel(l10n, s), isNotEmpty);
      }
      for (final t in VisitType.values) {
        expect(visitTypeLabel(l10n, t), isNotEmpty);
      }
      for (final r in VisitorRole.values) {
        expect(visitorRoleLabel(l10n, r), isNotEmpty);
      }
      for (final k in ProviderKind.values) {
        expect(providerKindLabel(l10n, k), isNotEmpty);
      }
      for (final r in Recurrence.values) {
        expect(recurrenceLabel(l10n, r), isNotEmpty);
      }
      expect(
        visitStatusLabel(l10n, VisitStatus.inside),
        l10n.visitsStatusInside,
      );
      expect(visitTypeLabel(l10n, VisitType.fastlane), l10n.visitsTypeFastlane);
      expect(
        recurrenceLabel(l10n, Recurrence.monFri),
        l10n.visitsRecurrenceMonFri,
      );
    });

    test('visitTypeFromString falls back to frequent', () {
      expect(visitTypeFromString('fastlane'), VisitType.fastlane);
      expect(visitTypeFromString('delivery'), VisitType.delivery);
      expect(visitTypeFromString('x'), VisitType.frequent);
    });

    test('recurrence db round trip', () {
      for (final r in Recurrence.values) {
        expect(recurrenceFromString(recurrenceToDb(r)), r);
      }
      expect(recurrenceToDb(Recurrence.monFri), 'mon_fri');
      expect(recurrenceFromString('nope'), Recurrence.daily);
    });

    test('weekdayShortLabel maps keys, defaulting to Sunday', () {
      final labels = [for (final d in weekdayKeys) weekdayShortLabel(l10n, d)];
      expect(labels.toSet().length, 7);
      expect(weekdayShortLabel(l10n, 'sun'), l10n.visitsWeekdaySun);
      expect(weekdayShortLabel(l10n, '???'), l10n.visitsWeekdaySun);
    });

    test('timeToDb / timeFromDb', () {
      expect(timeToDb(const TimeOfDay(hour: 8, minute: 5)), '08:05:00');
      expect(timeToDb(const TimeOfDay(hour: 23, minute: 59)), '23:59:00');
      expect(timeFromDb('07:30:00'), const TimeOfDay(hour: 7, minute: 30));
      expect(timeFromDb('21:00'), const TimeOfDay(hour: 21, minute: 0));
    });
  });

  group('ScheduleBlock', () {
    const block = ScheduleBlock(
      days: {'fri', 'mon'},
      start: TimeOfDay(hour: 8, minute: 0),
      end: TimeOfDay(hour: 10, minute: 0),
    );

    test('toMap orders days Monday first', () {
      expect(block.toMap(), {
        'days': ['mon', 'fri'],
        'start': '08:00:00',
        'end': '10:00:00',
      });
    });

    test('fromMap(toMap) round trips', () {
      final back = ScheduleBlock.fromMap(block.toMap());
      expect(back.days, block.days);
      expect(back.start, block.start);
      expect(back.end, block.end);
    });

    test('copyWith replaces only given fields', () {
      final c = block.copyWith(end: const TimeOfDay(hour: 12, minute: 15));
      expect(c.days, block.days);
      expect(c.start, block.start);
      expect(c.end, const TimeOfDay(hour: 12, minute: 15));
      final d = block.copyWith(
        days: {'sun'},
        start: const TimeOfDay(hour: 1, minute: 0),
      );
      expect(d.days, {'sun'});
      expect(d.start.hour, 1);
      expect(d.end, block.end);
    });
  });

  group('AccessMovement', () {
    test('open movement is inside', () {
      final m = AccessMovement.fromMap({
        'checked_in_at': '2026-09-30T14:00:00Z',
      });
      expect(m.isInside, isTrue);
      expect(m.checkedOutAt, isNull);
      expect(m.checkedInAt.toUtc(), DateTime.utc(2026, 9, 30, 14));
    });

    test('closed movement is not inside', () {
      final m = AccessMovement.fromMap({
        'checked_in_at': '2026-09-30T14:00:00Z',
        'checked_out_at': '2026-09-30T16:00:00Z',
      });
      expect(m.isInside, isFalse);
      expect(m.checkedOutAt!.toUtc(), DateTime.utc(2026, 9, 30, 16));
    });
  });

  group('ProviderCatalogItem', () {
    test('fromMap parses and defaults unknown kind to delivery', () {
      final a = ProviderCatalogItem.fromMap({
        'id': 'p1',
        'residential_id': 'r1',
        'name': 'DHL',
        'kind': 'paqueteria',
        'logo_url': 'http://x/logo.png',
      });
      expect(a.kind, ProviderKind.paqueteria);
      expect(a.residentialId, 'r1');
      expect(a.logoUrl, 'http://x/logo.png');
      final b = ProviderCatalogItem.fromMap({
        'id': 'p2',
        'residential_id': null,
        'name': 'X',
        'kind': 'zzz',
      });
      expect(b.kind, ProviderKind.delivery);
      expect(b.residentialId, isNull);
      expect(b.logoUrl, isNull);
    });

    test('providerInitials', () {
      expect(providerInitials('Control de plagas'), 'CD');
      expect(providerInitials('DHL'), 'D');
      expect(providerInitials('  uber   eats  '), 'UE');
      expect(providerInitials('   '), '');
      expect(providerInitials(''), '');
    });
  });

  group('formatters', () {
    test('formatClockField / formatClockText', () {
      expect(formatClockField(const TimeOfDay(hour: 8, minute: 0)), '08:00 AM');
      expect(
        formatClockField(const TimeOfDay(hour: 22, minute: 5)),
        '10:05 PM',
      );
      expect(
        formatClockText(const TimeOfDay(hour: 8, minute: 0)),
        contains('8:00'),
      );
    });

    Visit frequent({
      Recurrence? recurrence,
      ScheduleType? type,
      TimeOfDay? start,
      TimeOfDay? end,
      List<ScheduleBlock>? blocks,
    }) => Visit(
      id: '1',
      unitId: 'u',
      status: VisitStatus.scheduled,
      visitType: VisitType.frequent,
      recurrence: recurrence,
      scheduleType: type,
      scheduleStart: start,
      scheduleEnd: end,
      scheduleBlocks: blocks,
      validFrom: DateTime(2026),
      validUntil: DateTime(2099),
      createdAt: DateTime(2026),
    );

    test('frequentScheduleSummary variants', () {
      expect(
        frequentScheduleSummary(l10n, frequent()),
        '${l10n.visitsFrequentAccess} · ${l10n.visitsAllDay}',
      );
      final windowed = frequentScheduleSummary(
        l10n,
        frequent(
          recurrence: Recurrence.daily,
          type: ScheduleType.custom,
          start: const TimeOfDay(hour: 9, minute: 0),
          end: const TimeOfDay(hour: 17, minute: 0),
        ),
      );
      expect(windowed, startsWith('${l10n.visitsRecurrenceDaily} · '));
      expect(windowed, contains('9:00'));
      expect(windowed, contains('5:00'));
      // custom type without times falls back to all day
      expect(
        frequentScheduleSummary(
          l10n,
          frequent(recurrence: Recurrence.daily, type: ScheduleType.custom),
        ),
        endsWith(l10n.visitsAllDay),
      );
      // custom recurrence with empty blocks falls back to the preset text
      expect(
        frequentScheduleSummary(
          l10n,
          frequent(recurrence: Recurrence.custom, blocks: const []),
        ),
        '${l10n.visitsRecurrenceCustom} · ${l10n.visitsAllDay}',
      );
      final multi = frequentScheduleSummary(
        l10n,
        frequent(
          recurrence: Recurrence.custom,
          blocks: const [
            ScheduleBlock(
              days: {'wed', 'mon'},
              start: TimeOfDay(hour: 8, minute: 0),
              end: TimeOfDay(hour: 10, minute: 0),
            ),
            ScheduleBlock(
              days: {'sat'},
              start: TimeOfDay(hour: 9, minute: 0),
              end: TimeOfDay(hour: 12, minute: 0),
            ),
          ],
        ),
      );
      final lines = multi.split('\n');
      expect(lines, hasLength(2));
      expect(lines[0], startsWith('Lun, Mié · '));
      expect(lines[1], startsWith('Sáb · '));
    });

    test('lastMovementLabel today / yesterday / older, entry vs exit', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 8, 5);
      final entry = lastMovementLabel(l10n, AccessMovement(checkedInAt: today));
      expect(entry, contains(l10n.visitsMovementDayToday));

      final yesterday = today.subtract(const Duration(days: 1));
      final exit = lastMovementLabel(
        l10n,
        AccessMovement(
          checkedInAt: yesterday.subtract(const Duration(hours: 1)),
          checkedOutAt: yesterday,
        ),
      );
      expect(exit, contains(l10n.visitsMovementDayYesterday));

      final old = lastMovementLabel(
        l10n,
        AccessMovement(checkedInAt: DateTime(2020, 3, 5, 18, 30)),
      );
      expect(old, contains('5 mar.'));
    });

    test('formatVisitDate says today / tomorrow / plain', () {
      final now = DateTime.now();
      expect(formatVisitDate(l10n, now), startsWith('Hoy'));
      expect(
        formatVisitDate(l10n, now.add(const Duration(days: 1))),
        startsWith('Mañana'),
      );
      final far = formatVisitDate(l10n, DateTime(2031, 1, 5));
      expect(far, contains('2031'));
      expect(far, isNot(contains('Hoy')));
      expect(far, isNot(contains('Mañana')));
    });

    test('withFailureDetail / withErrorDetail prefix the cause', () {
      expect(
        withFailureDetail(l10n, const NetworkFailure(), 'Falló.'),
        '${l10n.commonErrorNetwork} Falló.',
      );
      expect(
        withFailureDetail(l10n, const UnknownFailure(), 'Falló.'),
        'Falló.',
      );
      expect(
        withErrorDetail(l10n, const AuthFailure(), 'Falló.'),
        '${l10n.commonErrorSession} Falló.',
      );
      expect(withErrorDetail(l10n, StateError('x'), 'Falló.'), 'Falló.');
    });
  });

  group('fastlaneLink', () {
    tearDown(() => dotenv.loadFromString(envString: 'OTHER=1'));

    test('defaults to the production public URL', () {
      dotenv.loadFromString(envString: 'OTHER=1');
      expect(fastlaneLink('ABC'), 'https://vecinoo.app/#fastlane/ABC');
    });

    test('adds a missing trailing slash and respects PUBLIC_APP_URL', () {
      dotenv.loadFromString(envString: 'PUBLIC_APP_URL=https://x.test');
      expect(fastlaneLink('Z9'), 'https://x.test/#fastlane/Z9');
      dotenv.loadFromString(envString: 'PUBLIC_APP_URL=https://x.test/');
      expect(fastlaneLink('Z9'), 'https://x.test/#fastlane/Z9');
    });
  });
}

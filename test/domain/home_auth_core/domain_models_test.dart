import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/features/profile/domain/profile.dart';
import 'package:gates_app/features/session/domain/invitation.dart';
import 'package:gates_app/features/session/domain/membership.dart';

void main() {
  group('Membership', () {
    test('fromMap reads the nested unit and residential', () {
      final m = Membership.fromMap({
        'units': {
          'id': 'u1',
          'name': 'A-204',
          'residentials': {'id': 'r1', 'name': 'Los Olivos'},
        },
      });
      expect(m.unitId, 'u1');
      expect(m.unitName, 'A-204');
      expect(m.residentialId, 'r1');
      expect(m.residentialName, 'Los Olivos');
      expect(m.label, 'A-204 · Los Olivos');
    });

    test('fromMap fails loudly when the nesting is missing', () {
      expect(() => Membership.fromMap({}), throwsA(isA<TypeError>()));
    });
  });

  group('InvitationPreview', () {
    test('fromMap with every field', () {
      final p = InvitationPreview.fromMap({
        'unit_name': 'B-1',
        'residential_name': 'Pinos',
        'email': 'a@b.c',
        'phone': '+5041',
        'full_name': 'Ana Perez',
      });
      expect(p.unitName, 'B-1');
      expect(p.residentialName, 'Pinos');
      expect(p.email, 'a@b.c');
      expect(p.phone, '+5041');
      expect(p.fullName, 'Ana Perez');
    });

    test('optional fields may be null', () {
      final p = InvitationPreview.fromMap({
        'unit_name': 'B-1',
        'residential_name': 'Pinos',
        'email': 'a@b.c',
      });
      expect(p.phone, isNull);
      expect(p.fullName, isNull);
    });
  });

  group('EmailLoginStatus.fromString', () {
    test('maps known values and defaults to unknown', () {
      expect(EmailLoginStatus.fromString('active'), EmailLoginStatus.active);
      expect(EmailLoginStatus.fromString('invited'), EmailLoginStatus.invited);
      expect(EmailLoginStatus.fromString('unknown'), EmailLoginStatus.unknown);
      expect(EmailLoginStatus.fromString('???'), EmailLoginStatus.unknown);
    });
  });

  group('Profile', () {
    test('fromMap', () {
      final p = Profile.fromMap({
        'user_id': 'u',
        'email': 'a@b.c',
        'first_name': 'Ana',
        'last_name': 'Perez',
        'phone': '+5049',
      });
      expect(p.userId, 'u');
      expect(p.email, 'a@b.c');
      expect(p.firstName, 'Ana');
      expect(p.lastName, 'Perez');
      expect(p.phone, '+5049');
    });

    test('isComplete needs both names', () {
      expect(
        const Profile(userId: 'u', firstName: 'A', lastName: 'B').isComplete,
        isTrue,
      );
      expect(const Profile(userId: 'u', firstName: 'A').isComplete, isFalse);
      expect(
        const Profile(userId: 'u', firstName: ' ', lastName: 'B').isComplete,
        isFalse,
      );
    });

    test('displayName prefers the full name then email, phone, fallback', () {
      expect(
        const Profile(
          userId: 'u',
          firstName: 'Ana',
          lastName: 'Perez',
        ).displayName,
        'Ana Perez',
      );
      expect(
        const Profile(userId: 'u', firstName: 'Ana', lastName: ' ').displayName,
        'Ana',
      );
      expect(
        const Profile(userId: 'u', email: 'a@b.c', phone: '1').displayName,
        'a@b.c',
      );
      expect(const Profile(userId: 'u', phone: '1').displayName, '1');
      expect(const Profile(userId: 'u').displayName, 'Residente');
    });
  });
}

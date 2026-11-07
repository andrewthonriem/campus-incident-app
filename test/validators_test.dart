import 'package:campus_incident_app/utils/validators.dart';
import 'package:campus_incident_app/utils/alu_email.dart';
import 'package:campus_incident_app/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthService.friendlyError', () {
    test('explains Firebase profile permission failures', () {
      expect(
        AuthService.friendlyError(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        ),
        contains('latest Firestore rules are deployed'),
      );
    });

    test('explains when the account exists but the password did not match', () {
      expect(
        AuthService.friendlyError(
          ArgumentError(
            'An account already exists for this email. Use the correct '
            'password or sign in from the login screen.',
          ),
        ),
        contains('sign in from the login screen'),
      );
    });
  });

  group('Validators.email', () {
    test('rejects empty and malformed', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email('a..b@alustudent.com'), isNotNull);
      expect(Validators.email('.a@alustudent.com'), isNotNull);
      expect(Validators.email('a@-alu.edu'), isNotNull);
      expect(Validators.email('a@alu-.edu'), isNotNull);
    });
    test('accepts a valid address', () {
      expect(Validators.email('a.student@alustudent.com'), isNull);
    });
  });

  group('Validators.aluEmail', () {
    test('accepts both ALU domains without case sensitivity', () {
      expect(Validators.aluEmail('a.student@alustudent.com'), isNull);
      expect(Validators.aluEmail('staff@ALU.EDU'), isNull);
      expect(Validators.aluEmail('staff@ALUEDU.COM'), isNull);
    });

    test('rejects non-ALU domains', () {
      expect(Validators.aluEmail('student@example.com'), isNotNull);
      expect(Validators.aluEmail('student@notalu.edu'), isNotNull);
    });

    test('identifies @aluedu.com addresses as staff accounts', () {
      expect(isAluStaffEmail('staff@aluedu.com'), isTrue);
      expect(isAluStaffEmail('staff@ALUEDU.COM'), isTrue);
      expect(isAluStaffEmail('staff@alu.edu'), isFalse);
      expect(isAluStaffEmail('student@example.com'), isFalse);
    });
  });

  group('Validators.password', () {
    test('requires at least 6 characters', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });
    test('confirmPassword must match', () {
      final v = Validators.confirmPassword(() => 'secret1');
      expect(v('secret2'), isNotNull);
      expect(v('secret1'), isNull);
    });
  });

  group('Report form validators', () {
    test('title length bounds', () {
      expect(Validators.title('abc'), isNotNull);
      expect(Validators.title('Broken tap'), isNull);
      expect(Validators.title('x' * 81), isNotNull);
    });
    test('description needs detail', () {
      expect(Validators.description('Too short'), isNotNull);
      expect(Validators.description('No water on the 2nd floor since 8am.'),
          isNull);
    });
    test('location required', () {
      expect(Validators.location('  '), isNotNull);
      expect(Validators.location('Block B'), isNull);
    });
  });
}

import 'package:campus_incident_app/utils/firebase_error_message.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('explains invalid-argument without blaming the network', () {
    final message = firebaseErrorMessage(
      FirebaseException(plugin: 'cloud_firestore', code: 'invalid-argument'),
      action: 'update the report',
    );

    expect(message, contains('invalid-argument'));
    expect(message, isNot(contains('connection')));
  });

  test('explains permission failures in terms of rules and account access', () {
    final message = firebaseErrorMessage(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      action: 'save the report',
    );

    expect(message, contains('account access'));
    expect(message, contains('Firestore rules'));
  });

  test('uses a connection hint only for service availability failures', () {
    final message = firebaseErrorMessage(
      FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      action: 'withdraw the report',
    );

    expect(message, contains('connection'));
  });

  test('shows Firebase error codes in debug builds', () {
    final message = firebaseErrorMessage(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      action: 'update the report',
    );

    if (kDebugMode) {
      expect(message, contains('Firebase error code: permission-denied'));
    }
  });
}

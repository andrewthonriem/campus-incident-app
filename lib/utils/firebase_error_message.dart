import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

String firebaseErrorMessage(FirebaseException error, {required String action}) {
  final message = switch (error.code) {
    'permission-denied' =>
      'Firebase denied permission to $action. Check your account access '
          'and make sure the latest Firestore rules are deployed.',
    'invalid-argument' =>
      'Firebase rejected the data for $action (invalid-argument). '
          'Please try again; if it continues, contact support.',
    'unauthenticated' => 'Your session has expired. Sign in again to $action.',
    'not-found' =>
      'The report could not be found. Refresh the report list and try again.',
    'failed-precondition' =>
      'Firebase is not ready to $action. Check your Firestore setup and try again.',
    'resource-exhausted' =>
      'Firebase storage limits were reached while trying to $action. Try again later.',
    'unavailable' ||
    'deadline-exceeded' =>
      'Firebase is temporarily unavailable. Check your connection and try again.',
    _ => 'Could not $action. Please try again.',
  };
  return kDebugMode ? '$message (Firebase error code: ${error.code})' : message;
}

String withDebugFirebaseErrorCode(String message, Object error) {
  if (!kDebugMode || error is! FirebaseException) return message;
  return '$message (Firebase error code: ${error.code})';
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../utils/alu_email.dart';

class RegistrationResult {
  const RegistrationResult({
    required this.created,
    required this.isStaff,
    required this.verificationEmailSent,
    required this.emailVerified,
  });

  final bool created;
  final bool isStaff;
  final bool verificationEmailSent;
  final bool emailVerified;
}

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> authStateChanges() => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  /// Live profile stream so role changes made by an admin apply immediately.
  Stream<AppUser?> profileStream(String uid) {
    return _userDoc(uid).snapshots().map(
          (snap) => snap.exists ? AppUser.fromMap(uid, snap.data()!) : null,
        );
  }

  Future<void> createProfileIfMissing(User user) async {
    final email = (user.email ?? '').trim().toLowerCase();
    final displayName = user.displayName?.trim();
    final name = displayName != null && displayName.isNotEmpty
        ? displayName
        : email.split('@').first;
    final role = isAluStaffEmail(email) ? UserRole.staff : UserRole.student;
    final reference = _userDoc(user.uid);

    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);
        if (snapshot.exists) return;
        transaction.set(reference, {
          'name': name,
          'email': email,
          'role': role.name,
          'department': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } on Object catch (e, st) {
      debugPrint('Update failed: $e\n$st');
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    if (!isAluEmail(email)) {
      throw ArgumentError(
        'Use your ALU email (@alustudent.com, @alu.edu, or @aluedu.com).',
      );
    }
    await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  /// Creates the auth account and the profile document.
  /// @aluedu.com accounts are staff and can use the app without verification.
  /// Other ALU accounts are students and must verify their email.
  Future<RegistrationResult> register({
    required String name,
    required String email,
    required String password,
    String department = '',
  }) async {
    if (!isAluEmail(email)) {
      throw ArgumentError(
        'Use your ALU email (@alustudent.com, @alu.edu, or @aluedu.com).',
      );
    }
    final normalizedEmail = email.trim().toLowerCase();
    final staffAccount = isAluStaffEmail(normalizedEmail);
    User user;
    var created = true;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final createdUser = credential.user;
      if (createdUser == null) {
        throw StateError('Firebase did not return the newly created account.');
      }
      user = createdUser;
      try {
        await user.updateDisplayName(name.trim());
        await _userDoc(user.uid).set(
          AppUser(
            uid: user.uid,
            name: name.trim(),
            email: normalizedEmail,
            role: staffAccount ? UserRole.staff : UserRole.student,
            department: department.trim(),
          ).toMap(),
        );
      } on Object catch (e, st) {
        debugPrint('Update failed: $e\n$st');
        try {
          await user.delete();
        } on Object catch (rollbackError, rollbackStackTrace) {
          debugPrint('Update failed: $rollbackError\n$rollbackStackTrace');
          Error.throwWithStackTrace(
            StateError(
              'The account was created, but profile setup failed and Firebase '
              'could not roll the account back. Try signing in with this email '
              'and password to complete setup. Details: $e; '
              'rollback: $rollbackError',
            ),
            rollbackStackTrace,
          );
        }
        Error.throwWithStackTrace(e, st);
      }
    } on FirebaseAuthException catch (error) {
      if (error.code != 'email-already-in-use') rethrow;
      final credential = await _signInForRegistrationRecovery(
        normalizedEmail,
        password,
      );
      final existingUser = credential.user;
      if (existingUser == null) {
        throw StateError('Firebase did not return the existing account.');
      }
      user = existingUser;
      created = false;
      final profile = await _userDoc(user.uid).get();
      if (!profile.exists) {
        await user.updateDisplayName(name.trim());
        await createProfileIfMissing(user);
      }
    }

    var verificationEmailSent = true;
    if (!staffAccount && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
      } on Object catch (error, stackTrace) {
        debugPrint('Could not send verification email: $error');
        debugPrintStack(stackTrace: stackTrace);
        verificationEmailSent = false;
      }
    }
    return RegistrationResult(
      created: created,
      isStaff: staffAccount,
      verificationEmailSent: verificationEmailSent,
      emailVerified: user.emailVerified,
    );
  }

  Future<UserCredential> _signInForRegistrationRecovery(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code == 'invalid-credential' ||
          error.code == 'wrong-password' ||
          error.code == 'user-not-found') {
        throw ArgumentError(
          'An account already exists for this email. Use the correct password '
          'or sign in from the login screen.',
        );
      }
      rethrow;
    }
  }

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in account to verify.');
    await user.sendEmailVerification();
  }

  Future<void> refreshCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in account to verify.');
    await user.reload();
    await _auth.currentUser?.getIdToken(true);
  }

  Future<void> sendPasswordReset(String email) {
    if (!isAluEmail(email)) {
      throw ArgumentError(
        'Use your ALU email (@alustudent.com, @alu.edu, or @aluedu.com).',
      );
    }
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => _auth.signOut();

  static String friendlyError(Object error) {
    if (error is ArgumentError) {
      return error.message?.toString() ?? error.toString();
    }
    if (error is StateError) return error.message.toString();
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'Firebase denied profile creation. Confirm the latest Firestore '
          'rules are deployed to the same Firebase project as the app and allow '
          'your email domain and account role.';
    }
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'That email address is not valid.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'weak-password':
          return 'Password is too weak (use at least 6 characters).';
        case 'operation-not-allowed':
          return 'Email/password sign-in is disabled in Firebase Authentication. '
              'Enable the Email/Password provider in the Firebase console.';
        case 'network-request-failed':
          return 'No internet connection. Please try again.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        default:
          return error.message ?? 'Authentication failed.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}

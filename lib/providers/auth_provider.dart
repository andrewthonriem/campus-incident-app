import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../utils/alu_email.dart';
import '../utils/firebase_error_message.dart';

enum AuthStatus {
  unknown,
  signedOut,
  requiresEmailVerification,
  profileUnavailable,
  signedIn
}

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service) {
    _authSub = _service.authStateChanges().listen(_onAuthChanged);
  }

  final AuthService _service;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  bool _busy = false;
  bool _registrationInProgress = false;
  String? _error;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isBusy => _busy;
  String? get error => _error;
  bool get isStaff => _user?.isStaff ?? false;

  void _onAuthChanged(User? firebaseUser) {
    if (_registrationInProgress) return;
    _profileSub?.cancel();
    if (firebaseUser == null) {
      _user = null;
      _status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    if (!isAluEmail(firebaseUser.email)) {
      _user = null;
      _status = AuthStatus.signedOut;
      notifyListeners();
      unawaited(_service.signOut());
      return;
    }
    if (!firebaseUser.emailVerified && !isAluStaffEmail(firebaseUser.email)) {
      _user = AppUser(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? firebaseUser.email ?? 'User',
        email: firebaseUser.email ?? '',
        role: UserRole.student,
      );
      _status = AuthStatus.requiresEmailVerification;
      notifyListeners();
      return;
    }
    _profileSub = _service.profileStream(firebaseUser.uid).listen((profile) {
      if (_service.currentUser?.uid != firebaseUser.uid) return;
      if (profile == null) {
        _user = _profileFromAuth(firebaseUser);
        _error = null;
        _status = AuthStatus.signedIn;
        notifyListeners();
        unawaited(_createMissingProfile(firebaseUser));
        return;
      }
      _user = _withStaffDomainRole(firebaseUser, profile);
      _error = null;
      _status = AuthStatus.signedIn;
      notifyListeners();
    }, onError: (Object error, StackTrace stackTrace) {
      if (_service.currentUser?.uid != firebaseUser.uid) return;
      final code = error is FirebaseException ? error.code : 'unknown';
      debugPrint('Update failed: $error\n$stackTrace');
      _user = null;
      _error = withDebugFirebaseErrorCode(
        'Your account profile could not be loaded '
        '(error code: $code). Check your connection and retry.',
        error,
      );
      _status = AuthStatus.profileUnavailable;
      notifyListeners();
    });
  }

  AppUser _profileFromAuth(User firebaseUser) {
    final email = (firebaseUser.email ?? '').trim().toLowerCase();
    final displayName = firebaseUser.displayName?.trim();
    return AppUser(
      uid: firebaseUser.uid,
      name: displayName != null && displayName.isNotEmpty
          ? displayName
          : email.split('@').first,
      email: email,
      role: isAluStaffEmail(email) ? UserRole.staff : UserRole.student,
    );
  }

  AppUser _withStaffDomainRole(User firebaseUser, AppUser profile) {
    if (!isAluStaffEmail(firebaseUser.email) || profile.isStaff) {
      return profile;
    }
    return AppUser(
      uid: profile.uid,
      name: profile.name,
      email: profile.email,
      role: UserRole.staff,
      department: profile.department,
      createdAt: profile.createdAt,
    );
  }

  Future<void> _createMissingProfile(User firebaseUser) async {
    try {
      await _service.createProfileIfMissing(firebaseUser);
    } on Object catch (error, stackTrace) {
      final code = error is FirebaseException ? error.code : 'unknown';
      debugPrint('Update failed: $error\n$stackTrace');
      if (_service.currentUser?.uid != firebaseUser.uid) return;
      _user = null;
      _error = withDebugFirebaseErrorCode(
        'Your account profile could not be created '
        '(error code: $code). Check your account and retry.',
        error,
      );
      _status = AuthStatus.profileUnavailable;
      notifyListeners();
    }
  }

  void retryProfileLoad() {
    _error = null;
    _onAuthChanged(_service.currentUser);
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on Object catch (e, st) {
      debugPrint('Update failed: $e\n$st');
      _error = withDebugFirebaseErrorCode(AuthService.friendlyError(e), e);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) =>
      _run(() => _service.signIn(email: email, password: password));

  Future<RegistrationResult?> register({
    required String name,
    required String email,
    required String password,
    String department = '',
  }) async {
    _busy = true;
    _registrationInProgress = true;
    _error = null;
    notifyListeners();
    try {
      return await _service.register(
        name: name,
        email: email,
        password: password,
        department: department,
      );
    } on Object catch (error, stackTrace) {
      debugPrint('Update failed: $error\n$stackTrace');
      _error = withDebugFirebaseErrorCode(
        AuthService.friendlyError(error),
        error,
      );
      return null;
    } finally {
      _registrationInProgress = false;
      _onAuthChanged(_service.currentUser);
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) =>
      _run(() => _service.sendPasswordReset(email));

  Future<bool> resendVerificationEmail() =>
      _run(_service.resendVerificationEmail);

  Future<bool> checkEmailVerification() async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _service.refreshCurrentUser();
      return _service.currentUser?.emailVerified ?? false;
    } on Object catch (e, st) {
      debugPrint('Update failed: $e\n$st');
      _error = withDebugFirebaseErrorCode(AuthService.friendlyError(e), e);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() => _service.signOut();

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../models/incident_category.dart';
import '../models/incident_status.dart';
import '../services/incident_repository.dart';
import '../utils/incident_filter.dart';

class IncidentProvider extends ChangeNotifier {
  IncidentProvider(this._repo);

  final IncidentRepository _repo;
  StreamSubscription<List<Incident>>? _sub;

  AppUser? _user;
  List<Incident> _all = const [];
  IncidentFilter _filter = const IncidentFilter();
  bool _loading = true;
  String? _error;

  bool _submitting = false;
  double? _uploadProgress;
  String? _uploadStage;

  bool get isLoading => _loading;
  String? get error => _error;
  bool get isSubmitting => _submitting;
  double? get uploadProgress => _uploadProgress;
  String? get uploadStage => _uploadStage;
  IncidentFilter get filter => _filter;
  AppUser? get user => _user;

  List<Incident> get all => _all;

  List<Incident> get myIncidents =>
      _all.where((i) => i.reporterId == _user?.uid).toList();

  List<Incident> get filtered =>
      applyIncidentFilter(_all, _filter, currentUid: _user?.uid);

  /// Students see a summary of their own reports; staff see the whole campus.
  Map<IncidentStatus, int> get summary =>
      countByStatus(_user?.isStaff == true ? _all : myIncidents);

  int get summaryTotal => summary.values.fold(0, (a, b) => a + b);

  Incident? byId(String id) {
    for (final i in _all) {
      if (i.id == id) return i;
    }
    return null;
  }

  /// Called by ChangeNotifierProxyProvider whenever the signed-in user changes.
  void bindUser(AppUser? user) {
    final changedAccount = user?.uid != _user?.uid;
    _user = user;
    if (!changedAccount) return;

    _sub?.cancel();
    _all = const [];
    _filter = const IncidentFilter();
    if (user == null) {
      _loading = false;
      // bindUser runs inside ProxyProvider.update (during build), so the
      // notification is deferred to avoid "markNeedsBuild during build".
      scheduleMicrotask(_notifyIfAlive);
      return;
    }
    _loading = true;
    scheduleMicrotask(_notifyIfAlive);
    _sub = _repo.watchAll().listen(
      (list) {
        _all = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = 'Could not load reports. Check your connection.';
        notifyListeners();
      },
    );
  }

  bool _disposed = false;

  void _notifyIfAlive() {
    if (!_disposed) notifyListeners();
  }

  void setQuery(String q) {
    _filter = _filter.copyWith(query: q);
    notifyListeners();
  }

  void setCategory(IncidentCategory? c) {
    _filter = _filter.copyWith(category: () => c);
    notifyListeners();
  }

  void setStatus(IncidentStatus? s) {
    _filter = _filter.copyWith(status: () => s);
    notifyListeners();
  }

  void setMineOnly(bool mine) {
    _filter = _filter.copyWith(mineOnly: mine);
    notifyListeners();
  }

  void clearFilters() {
    _filter = const IncidentFilter();
    notifyListeners();
  }

  Future<String?> submit({
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    XFile? photo,
  }) async {
    final user = _user;
    if (user == null) throw StateError('Not signed in');
    _submitting = true;
    _uploadProgress = photo != null ? 0 : null;
    _uploadStage = photo != null ? 'Preparing photo…' : null;
    notifyListeners();
    try {
      return await _repo.submit(
        reporter: user,
        title: title,
        description: description,
        category: category,
        location: location,
        photo: photo,
        onUploadStage: (stage) {
          _uploadStage = stage;
          notifyListeners();
        },
        onUploadProgress: (p) {
          _uploadStage = 'Uploading photo…';
          _uploadProgress = p;
          notifyListeners();
        },
      );
    } on Object catch (e, st) {
      debugPrint('Update failed: $e\n$st');
      Error.throwWithStackTrace(e, st);
    } finally {
      _submitting = false;
      _uploadProgress = null;
      _uploadStage = null;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> updateStatus(Incident incident, IncidentStatus status,
      {String note = ''}) {
    final user = _user;
    if (user == null || !user.isStaff) {
      // Defence in depth: the UI hides the control and Firestore rules
      // reject it, but we also refuse here.
      return Future.error(StateError('Only staff can update incident status.'));
    }
    return _updateStatus(
      incident,
      status,
      user,
      note,
    );
  }

  Future<void> _updateStatus(
    Incident incident,
    IncidentStatus status,
    AppUser user,
    String note,
  ) async {
    try {
      await _repo.updateStatus(
        incidentId: incident.id,
        newStatus: status,
        staff: user,
        note: note,
      );
    } on Object catch (e, st) {
      debugPrint('Update failed: $e\n$st');
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> withdraw(Incident incident) async {
    try {
      await _repo.delete(incident);
    } on Object catch (e, st) {
      debugPrint('Update failed: $e\n$st');
      Error.throwWithStackTrace(e, st);
    }
  }

  Stream<Incident?> watch(String id) => _repo.watchOne(id);

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}

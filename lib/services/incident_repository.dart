import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../models/incident_category.dart';
import '../models/incident_status.dart';
import 'incident_photo_codec.dart';
import 'storage_service.dart';

class IncidentRepository {
  IncidentRepository({FirebaseFirestore? firestore, StorageService? storage})
      : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? StorageService();

  final FirebaseFirestore _db;
  final StorageService _storage;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('incidents');

  Stream<List<Incident>> watchAll({int limit = 200}) {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((q) => q.docs.map(Incident.fromDoc).toList());
  }

  Stream<Incident?> watchOne(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Incident.fromDoc(d) : null);

  /// Uploads the compressed image to Cloudinary, then saves its URL with the report.
  Future<String> submit({
    required AppUser reporter,
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    XFile? photo,
    void Function(String stage)? onUploadStage,
    void Function(double progress)? onUploadProgress,
  }) async {
    final doc = _col.doc();
    CompressedIncidentPhoto? compressedPhoto;
    String? imageUrl;
    String? imagePath;
    if (photo != null) {
      onUploadStage?.call('Compressing photo…');
      compressedPhoto = compressIncidentPhoto(await photo.readAsBytes());
      final uploaded = await _storage.uploadIncidentImage(
        uid: reporter.uid,
        incidentId: doc.id,
        bytes: compressedPhoto.bytes,
        onProgress: (progress) => onUploadProgress?.call(progress * 0.9),
      );
      imageUrl = uploaded.url;
      imagePath = uploaded.path;
    }

    final now = DateTime.now();
    try {
      await doc.set({
        'title': title.trim(),
        'description': description.trim(),
        'category': category.name,
        'location': location.trim(),
        'status': IncidentStatus.submitted.name,
        'reporterId': reporter.uid,
        'reporterName': reporter.name,
        'imageUrl': imageUrl,
        'imagePath': imagePath,
        'thumbnail':
            compressedPhoto == null ? null : Blob(compressedPhoto.thumbnail),
        'photoCount': compressedPhoto == null ? 0 : 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'history': [
          StatusChange(
            status: IncidentStatus.submitted,
            changedBy: reporter.uid,
            changedByName: reporter.name,
            at: now,
          ).toMap(),
        ],
      });
    } on Object catch (e, st) {
      debugPrint('Update failed: $e\n$st');
      if (imagePath != null) await _tryDeleteImage(imagePath);
      Error.throwWithStackTrace(e, st);
    }
    if (compressedPhoto != null) {
      onUploadProgress?.call(1);
      onUploadStage?.call('Report saved.');
    }
    return doc.id;
  }

  /// Staff-only: change the status and append to history.
  /// Firestore rules reject this call for non-staff users.
  Future<void> updateStatus({
    required String incidentId,
    required IncidentStatus newStatus,
    required AppUser staff,
    String note = '',
  }) async {
    final document = _col.doc(incidentId);
    try {
      await document.update({
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'history': FieldValue.arrayUnion([
          {
            'status': newStatus.name,
            'changedBy': staff.uid,
            'changedByName': staff.name,
            'note': note.trim(),
            'at': Timestamp.fromDate(DateTime.now()),
          },
        ]),
      });
    } on Object catch (e, st) {
      debugPrint('Update failed: $e\n$st');
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> _tryDeleteImage(String path) async {
    try {
      await _storage.deleteImage(path);
    } on Object catch (e, st) {
      debugPrint('Update failed: $e\n$st');
    }
  }

  /// A student may withdraw their own report while it is still "submitted".
  Future<void> delete(Incident incident) async {
    try {
      await _col.doc(incident.id).delete();
    } on Object catch (e, st) {
      debugPrint('Update failed: $e\n$st');
      Error.throwWithStackTrace(e, st);
    }
    if (incident.imagePath != null) {
      await _tryDeleteImage(incident.imagePath!);
    }
  }
}

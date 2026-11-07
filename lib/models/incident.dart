import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'incident_category.dart';
import 'incident_status.dart';

class StatusChange {
  const StatusChange({
    required this.status,
    required this.changedBy,
    required this.changedByName,
    required this.at,
    this.note = '',
  });

  final IncidentStatus status;
  final String changedBy;
  final String changedByName;
  final DateTime at;
  final String note;

  factory StatusChange.fromMap(Map<String, dynamic> map) {
    final at = map['at'];
    DateTime parseAt(Object? value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return StatusChange(
      status: IncidentStatus.fromName(map['status'] as String?),
      changedBy: (map['changedBy'] as String?) ?? '',
      changedByName: (map['changedByName'] as String?) ?? '',
      note: (map['note'] as String?) ?? '',
      at: parseAt(at),
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'changedBy': changedBy,
        'changedByName': changedByName,
        'note': note,
        // serverTimestamp() is not allowed inside arrays, so a client Timestamp is used.
        'at': Timestamp.fromDate(at),
      };
}

class Incident {
  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.imagePath,
    this.thumbnail,
    this.photoCount = 0,
    this.history = const [],
  });

  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final String location;
  final IncidentStatus status;
  final String reporterId;
  final String reporterName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl;
  final String? imagePath;
  final Uint8List? thumbnail;
  final int photoCount;
  final List<StatusChange> history;

  bool get hasImage =>
      photoCount > 0 ||
      thumbnail != null ||
      (imageUrl != null && imageUrl!.isNotEmpty);

  /// Returns the date at which [s] was reached, if it was.
  DateTime? reachedAt(IncidentStatus s) {
    for (final h in history) {
      if (h.status == s) return h.at;
    }
    return null;
  }

  factory Incident.fromMap(String id, Map<String, dynamic> map) {
    DateTime toDate(Object? v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final rawHistory = (map['history'] as List?) ?? const [];
    return Incident(
      id: id,
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      category: IncidentCategory.fromName(map['category'] as String?),
      location: (map['location'] as String?) ?? '',
      status: IncidentStatus.fromName(map['status'] as String?),
      reporterId: (map['reporterId'] as String?) ?? '',
      reporterName: (map['reporterName'] as String?) ?? '',
      createdAt: toDate(map['createdAt']),
      updatedAt: toDate(map['updatedAt']),
      imageUrl: map['imageUrl'] as String?,
      imagePath: map['imagePath'] as String?,
      thumbnail: _bytesFromMap(map['thumbnail']),
      photoCount: (map['photoCount'] as num?)?.toInt() ?? 0,
      history: rawHistory
          .whereType<Map>()
          .map((m) => StatusChange.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }

  factory Incident.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Incident.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'category': category.name,
        'location': location,
        'status': status.name,
        'reporterId': reporterId,
        'reporterName': reporterName,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'imageUrl': imageUrl,
        'imagePath': imagePath,
        'thumbnail': thumbnail == null ? null : Blob(thumbnail!),
        'photoCount': photoCount,
        'history': history.map((h) => h.toMap()).toList(),
      };

  static Uint8List? _bytesFromMap(Object? value) {
    if (value is Blob) return value.bytes;
    if (value is Uint8List) return value;
    if (value is List<int>) return Uint8List.fromList(value);
    return null;
  }
}

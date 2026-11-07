import 'dart:typed_data';

import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/models/incident_category.dart';
import 'package:campus_incident_app/models/incident_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Incident round-trips through toMap/fromMap', () {
    final created = DateTime(2026, 10, 15, 10, 24);
    final original = Incident(
      id: 'abc',
      title: 'Water shortage',
      description: 'No water on the second floor since morning.',
      category: IncidentCategory.water,
      location: 'Student Residence',
      status: IncidentStatus.inProgress,
      reporterId: 'u1',
      reporterName: 'Amina Hassan',
      createdAt: created,
      updatedAt: created,
      imageUrl: 'https://example.com/a.jpg',
      imagePath: 'incident_images/u1/abc.jpg',
      history: [
        StatusChange(
            status: IncidentStatus.submitted,
            changedBy: 'u1',
            changedByName: 'Amina Hassan',
            at: created),
        StatusChange(
            status: IncidentStatus.inProgress,
            changedBy: 's1',
            changedByName: 'Facilities Office',
            note: 'Plumber assigned',
            at: created.add(const Duration(hours: 4))),
      ],
    );

    final copy = Incident.fromMap('abc', original.toMap());
    expect(copy.title, original.title);
    expect(copy.category, IncidentCategory.water);
    expect(copy.status, IncidentStatus.inProgress);
    expect(copy.createdAt, created);
    expect(copy.history.length, 2);
    expect(copy.history.last.note, 'Plumber assigned');
    expect(copy.reachedAt(IncidentStatus.inProgress),
        created.add(const Duration(hours: 4)));
    expect(copy.reachedAt(IncidentStatus.resolved), isNull);
    expect(copy.hasImage, isTrue);
  });

  test('unknown enum values fall back safely', () {
    final i = Incident.fromMap('x', {
      'title': 'T',
      'category': 'aliens',
      'status': 'weird',
      'createdAt': Timestamp.fromDate(DateTime(2026)),
    });

    expect(i.category, IncidentCategory.facilities);
    expect(i.status, IncidentStatus.submitted);
    expect(i.hasImage, isFalse);
  });

  test('incident photo thumbnail bytes round-trip', () {
    final thumbnail = Uint8List.fromList([0xff, 0xd8, 0xff]);
    final incident = Incident.fromMap('photo-report', {
      'thumbnail': Blob(thumbnail),
      'photoCount': 1,
    });

    expect(incident.thumbnail, thumbnail);
    expect(incident.photoCount, 1);
    expect(incident.hasImage, isTrue);
    expect(incident.toMap()['thumbnail'], Blob(thumbnail));
    expect(Incident.fromMap('photo-report', incident.toMap()).thumbnail,
        thumbnail);
  });

  test('DateTime values parse without crashing', () {
    final created = DateTime(2026, 2, 15, 9, 30);
    final incident = Incident.fromMap('x', {
      'title': 'Broken door',
      'description': 'Door jammed on the east side of Block A.',
      'category': 'facilities',
      'location': 'Block A',
      'status': 'submitted',
      'reporterId': 'u1',
      'reporterName': 'Amina',
      'createdAt': created,
      'updatedAt': created.add(const Duration(minutes: 5)),
    });
    final user = AppUser.fromMap('u1', {
      'name': 'Amina',
      'email': 'a.student@alustudent.com',
      'role': 'student',
      'createdAt': created,
    });

    expect(incident.createdAt, created);
    expect(incident.updatedAt, created.add(const Duration(minutes: 5)));
    expect(user.createdAt, created);
  });

  test('AppUser role parsing and initials', () {
    final staff =
        AppUser.fromMap('s1', {'name': 'Grace Akol', 'role': 'staff'});
    final student = AppUser.fromMap('u1', {'name': 'amina', 'role': 'admin'});
    expect(staff.isStaff, isTrue);
    expect(staff.initials, 'GA');
    expect(student.isStaff, isFalse,
        reason: 'unknown roles must not grant staff access');
    expect(student.initials, 'A');
  });
}

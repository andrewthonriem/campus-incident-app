import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/models/incident_category.dart';
import 'package:campus_incident_app/models/incident_status.dart';
import 'package:campus_incident_app/utils/incident_filter.dart';
import 'package:flutter_test/flutter_test.dart';

Incident _incident({
  required String id,
  required String title,
  IncidentCategory category = IncidentCategory.water,
  IncidentStatus status = IncidentStatus.submitted,
  String reporterId = 'u1',
  String location = 'Block A',
  String description = 'Some description text',
}) {
  final now = DateTime(2026, 10, 15);
  return Incident(
    id: id,
    title: title,
    description: description,
    category: category,
    location: location,
    status: status,
    reporterId: reporterId,
    reporterName: 'Test',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  final data = [
    _incident(id: '1', title: 'Water shortage', location: 'Student Residence'),
    _incident(
        id: '2',
        title: 'Broken projector',
        category: IncidentCategory.facilities,
        status: IncidentStatus.inProgress,
        reporterId: 'u2',
        location: 'Block B'),
    _incident(
        id: '3',
        title: 'Overflowing bin',
        category: IncidentCategory.sanitation,
        status: IncidentStatus.resolved,
        location: 'Cafeteria'),
  ];

  group('applyIncidentFilter', () {
    test('empty filter returns everything', () {
      expect(applyIncidentFilter(data, const IncidentFilter()).length, 3);
    });

    test('search matches title case-insensitively', () {
      final r = applyIncidentFilter(data, const IncidentFilter(query: 'WATER'));
      expect(r.map((i) => i.id), ['1']);
    });

    test('search matches location', () {
      final r =
          applyIncidentFilter(data, const IncidentFilter(query: 'cafeteria'));
      expect(r.map((i) => i.id), ['3']);
    });

    test('filters by status', () {
      final r = applyIncidentFilter(
          data, const IncidentFilter(status: IncidentStatus.inProgress));
      expect(r.map((i) => i.id), ['2']);
    });

    test('filters by category', () {
      final r = applyIncidentFilter(
          data, const IncidentFilter(category: IncidentCategory.sanitation));
      expect(r.map((i) => i.id), ['3']);
    });

    test('mineOnly keeps only the current user\'s reports', () {
      final r = applyIncidentFilter(data, const IncidentFilter(mineOnly: true),
          currentUid: 'u1');
      expect(r.map((i) => i.id), ['1', '3']);
    });

    test('filters combine with AND semantics', () {
      final r = applyIncidentFilter(
        data,
        const IncidentFilter(mineOnly: true, status: IncidentStatus.resolved),
        currentUid: 'u1',
      );
      expect(r.map((i) => i.id), ['3']);
    });
  });

  test('copyWith can clear a nullable filter', () {
    const f = IncidentFilter(category: IncidentCategory.water);
    expect(f.copyWith(category: () => null).category, isNull);
    expect(f.copyWith(query: 'x').category, IncidentCategory.water);
  });

  test('countByStatus counts every status', () {
    final counts = countByStatus(data);
    expect(counts[IncidentStatus.submitted], 1);
    expect(counts[IncidentStatus.inProgress], 1);
    expect(counts[IncidentStatus.resolved], 1);
    expect(counts[IncidentStatus.rejected], 0);
  });
}

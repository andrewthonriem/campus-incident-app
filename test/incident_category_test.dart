import 'package:campus_incident_app/models/incident_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every incident category round-trips by its stored name', () {
    for (final category in IncidentCategory.values) {
      expect(IncidentCategory.fromName(category.name), category);
    }
  });

  test('unknown category names fall back to facilities', () {
    expect(
      IncidentCategory.fromName('unknown'),
      IncidentCategory.facilities,
    );
    expect(IncidentCategory.fromName(null), IncidentCategory.facilities);
  });
}

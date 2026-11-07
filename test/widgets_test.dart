import 'package:campus_incident_app/models/incident_category.dart';
import 'package:campus_incident_app/models/incident_status.dart';
import 'package:campus_incident_app/screens/report/report_form_screen.dart';
import 'package:campus_incident_app/widgets/category_selector.dart';
import 'package:campus_incident_app/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  test('Report locations use ALU buildings and accept optional room details',
      () {
    expect(
      kCampusBuildings,
      containsAll([
        'Social Commons',
        'Enterprise Commons',
        'Leadership Block',
      ]),
    );
    expect(kCampusBuildings, isNot(contains('Block A')));
    expect(kCampusBuildings, isNot(contains('Block B')));
    expect(
        composeIncidentLocation('Leadership Block', null), 'Leadership Block');
    expect(composeIncidentLocation('Social Commons', '  Room 12  '),
        'Social Commons — Room 12');
    expect(composeIncidentLocation('Enterprise Commons', '   '),
        'Enterprise Commons');
  });

  testWidgets('StatusBadge shows the status label', (tester) async {
    await tester.pumpWidget(
        _wrap(const StatusBadge(status: IncidentStatus.inProgress)));
    expect(find.text('In Progress'), findsOneWidget);
  });

  testWidgets('CategorySelector reports the tapped category', (tester) async {
    IncidentCategory? picked;
    await tester.pumpWidget(_wrap(SingleChildScrollView(
      child: CategorySelector(selected: null, onChanged: (c) => picked = c),
    )));

    for (final c in IncidentCategory.values) {
      expect(find.text(c.label), findsOneWidget);
    }
    await tester.tap(find.text('Electricity'));
    expect(picked, IncidentCategory.electricity);
  });

  testWidgets('CategorySelector shows validation error', (tester) async {
    await tester.pumpWidget(_wrap(SingleChildScrollView(
      child: CategorySelector(
        selected: null,
        onChanged: (_) {},
        errorText: 'Please choose a category',
      ),
    )));
    expect(find.text('Please choose a category'), findsOneWidget);
  });
}

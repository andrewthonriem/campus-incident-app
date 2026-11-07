import 'package:campus_incident_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows Firebase setup instructions and the startup error',
      (tester) async {
    await tester.pumpWidget(
      const FirebaseSetupApp(
        error: 'Firebase configuration is missing.',
      ),
    );

    expect(find.text('Campus Fix needs Firebase setup'), findsOneWidget);
    expect(find.textContaining('flutterfire configure'), findsOneWidget);
    expect(find.text('Firebase configuration is missing.'), findsOneWidget);
  });
}

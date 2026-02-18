import 'package:flutter_test/flutter_test.dart';
import 'package:agri_tech_app/main.dart'; // Import main.dart

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AgriTechApp());

    // Verify that the login screen appears
    expect(find.text('AgriTech'), findsOneWidget);
  });
}

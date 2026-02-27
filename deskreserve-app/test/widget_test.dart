import 'package:flutter_test/flutter_test.dart';
import 'package:deskreserve/main.dart';

void main() {
  testWidgets('DeskReserve login screen loads', (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(const DeskReserveApp());

    // Verify app title
    expect(find.text('DeskReserve'), findsOneWidget);

    // Verify tagline
    expect(find.text('Book. Study. Focus.'), findsOneWidget);

    // Verify login button
    expect(find.text('Login'), findsOneWidget);
  });
}

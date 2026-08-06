import 'package:flutter_test/flutter_test.dart';
import 'package:astro_app/main.dart';

void main() {
  testWidgets('AbcApp dashboard smoke test', (WidgetTester tester) async {
    // Build our app and trigger frames
    await tester.pumpWidget(const AbcApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Verify that ABC App title is present
    expect(find.text('ABC App'), findsOneWidget);
  });
}

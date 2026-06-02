import 'package:flutter_test/flutter_test.dart';

import 'package:mahatask/main.dart';

void main() {
  testWidgets('shows onboarding welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MahaTaskApp());

    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:admin_panel/app.dart';

void main() {
  testWidgets('admin dashboard renders navigation shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AlifAdminApp());
    await tester.pumpAndSettle();

    expect(find.text('Alif School'), findsOneWidget);
    expect(find.text('Admin Dashboard'), findsOneWidget);
    expect(find.text('Student Management'), findsOneWidget);
  });
}

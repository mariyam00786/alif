import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:admin_panel/app.dart';
import 'package:admin_panel/provider/admin_provider.dart';

void main() {
  testWidgets('admin dashboard renders login portal', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AdminProvider(),
        child: const AlifAdminApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Admin Portal'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
  });
}

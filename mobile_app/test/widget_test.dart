import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mobile_app/main.dart';
import 'package:mobile_app/provider/app_state_provider.dart';

void main() {
  testWidgets('App boots and shows login UI', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AppStateProvider())],
        child: const AlifMobileApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Student / Parent Portal'), findsOneWidget);
  });
}

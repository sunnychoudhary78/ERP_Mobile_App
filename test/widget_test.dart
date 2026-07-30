import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:erp_app/main.dart';

void main() {
  testWidgets('App boots to splash or login', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: const ErpApp(),
      ),
    );

    // First frame may show splash while auth initializes.
    await tester.pump();
    expect(find.byType(ErpApp), findsOneWidget);
  });
}

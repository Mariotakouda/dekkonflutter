import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekkon/app.dart';

void main() {
  testWidgets('DekkonApp démarre sans planter', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DekkonApp(),
      ),
    );

    expect(find.byType(DekkonApp), findsOneWidget);
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:app/main.dart';

void main() {
  testWidgets('App launches to menu screen', (WidgetTester tester) async {
    await tester.pumpWidget(const LodestonApp());
    expect(find.text('LODESTONE'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_jar_jar/app.dart';

void main() {
  testWidgets('POS app bootstraps', (WidgetTester tester) async {
    await tester.pumpWidget(const PosApp());
    expect(find.text('Shine Myan Thit'), findsOneWidget);
  });
}

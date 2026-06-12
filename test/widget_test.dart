import 'package:flutter_test/flutter_test.dart';
import 'package:cat_game/main.dart';

void main() {
  testWidgets('App starts without crashing smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CatGameApp());
    expect(find.text('Pegue o Gato'), findsWidgets);
  });
}

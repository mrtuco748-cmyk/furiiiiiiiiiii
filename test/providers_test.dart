import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:furi_app/main.dart';
import 'package:provider/provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('FuriApp registers providers in MultiProvider', (tester) async {
    await tester.pumpWidget(const FuriApp());
    expect(find.byType(MultiProvider), findsOneWidget);
  });
}

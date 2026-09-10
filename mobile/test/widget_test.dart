import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_mobile/main.dart';
import 'package:app_mobile/providers/auth_provider.dart';
import 'package:app_mobile/screens/login_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('widget_test: renders login when no saved session', (tester) async {
    final authProvider = AuthProvider();
    await authProvider.restore();
    await tester.pumpWidget(MyApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
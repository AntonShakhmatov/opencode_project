import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_mobile/main.dart';
import 'package:app_mobile/providers/auth_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app shows login screen when not authenticated', (tester) async {
    final authProvider = AuthProvider();
    await authProvider.restore();
    await tester.pumpWidget(MyApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    expect(find.text('Handyman App'), findsWidgets);
    expect(find.text('Login'), findsAtLeastNWidgets(1));
    expect(find.text('Email'), findsWidgets);
    expect(find.text('Password'), findsWidgets);
  });

  testWidgets('empty form shows validation errors', (tester) async {
    final authProvider = AuthProvider();
    await authProvider.restore();
    await tester.pumpWidget(MyApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('can navigate to register screen', (tester) async {
    final authProvider = AuthProvider();
    await authProvider.restore();
    await tester.pumpWidget(MyApp(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Don't have an account? Register"));
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
  });
}
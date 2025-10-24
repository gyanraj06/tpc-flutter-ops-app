import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tpc_ops/main.dart';
import 'package:tpc_ops/features/auth/presentation/providers/auth_provider.dart';

void main() {
  testWidgets('TPC Ops app smoke test', (WidgetTester tester) async {
    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const TPCOpsApp(),
      ),
    );

    // Wait for splash screen to load
    await tester.pumpAndSettle();

    // Verify that splash screen appears
    expect(find.text('TPC Ops'), findsWidgets);
  });
}

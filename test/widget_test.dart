import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifi_gamepad/main.dart';
import 'package:wifi_gamepad/screens/gamepad_screen.dart';

void main() {
  testWidgets('WiFi Gamepad menampilkan ConnectScreen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const WiFiGamepadApp());
    await tester.pumpAndSettle();

    expect(find.text('WiFi Gamepad'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
  });

  testWidgets(
    'GamepadScreen merender PlayStation & Xbox serta toggle Light/Dark tanpa overflow',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(852, 393);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: GamepadScreen()),
      );
      await tester.pumpAndSettle();

      // Default preset: PlayStation
      expect(find.text('L2'), findsOneWidget);
      expect(find.text('R2'), findsOneWidget);
      expect(find.text('L3'), findsOneWidget);
      expect(find.text('R3'), findsOneWidget);
      expect(find.text('TOUCHPAD'), findsOneWidget);

      // Toggle button size: Smaller (S) -> Larger (L) -> Normal (M)
      await tester.tap(find.text('S'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('L'));
      await tester.pumpAndSettle();

      // Switch to Xbox layout with Larger buttons
      await tester.tap(find.text('PS5'));
      await tester.pumpAndSettle();

      expect(find.text('LT'), findsOneWidget);
      expect(find.text('RT'), findsOneWidget);
      expect(find.text('LS'), findsOneWidget);
      expect(find.text('RS'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('X'), findsOneWidget);
      expect(find.text('Y'), findsOneWidget);

      // Toggle Light Mode & back to Normal size
      await tester.tap(find.text('M'));
      await tester.tap(find.byIcon(Icons.light_mode_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
    },
  );
}

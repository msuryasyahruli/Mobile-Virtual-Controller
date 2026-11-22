import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vcontrollers/main.dart';
import 'package:vcontrollers/screens/connect_screen.dart';
import 'package:vcontrollers/screens/gamepad_screen.dart';

void main() {
  testWidgets(
    'ConnectScreen reflows cleanly across compact, phone, and tablet widths with validation & theme toggle',
    (tester) async {
      for (final viewport in const [
        Size(320, 568), // Compact narrow phone (stacks IP & Port)
        Size(393, 852), // Standard phone portrait
        Size(768, 1024), // Tablet portrait
      ]) {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          VControllersApp(key: ValueKey('connect_$viewport')),
        );
        await tester.pumpAndSettle();

        expect(find.text('VControllers'), findsOneWidget);
        expect(find.text('Connect to PC'), findsOneWidget);
        expect(find.text('PlayStation'), findsOneWidget);
        expect(find.text('Xbox'), findsOneWidget);
        expect(find.text('Switch Pro'), findsOneWidget);

        // Empty submit shows inline validation
        await tester.tap(find.text('Connect to PC'));
        await tester.pumpAndSettle();
        expect(
          find.text('Enter a valid IPv4 address (e.g. 192.168.1.10)'),
          findsOneWidget,
        );

        // Toggle Light/Dark mode and layout preset
        await tester.tap(find.byIcon(Icons.light_mode_rounded));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);

        await tester.tap(find.text('Switch Pro'));
        await tester.pumpAndSettle();
      }

      tester.view.reset();
    },
  );

  testWidgets(
    'QuickMenuDrawer slides over PlayStation, Xbox, & Switch Pro with live state wiring and zero overflow across landscape viewports',
    (tester) async {
      for (final viewport in const [
        Size(667, 375), // Small landscape phone
        Size(852, 393), // Reference landscape artboard
        Size(932, 430), // Modern wide landscape phone
      ]) {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey('gamepad_$viewport'),
            routes: {
              '/': (_) => const ConnectScreen(),
              '/gamepad': (_) => GamepadScreen(key: ValueKey('screen_$viewport')),
            },
            initialRoute: '/gamepad',
          ),
        );
        await tester.pumpAndSettle();

        // Default preset: PlayStation (including M1 / M2 macros)
        expect(find.text('L2'), findsOneWidget);
        expect(find.text('M1'), findsOneWidget);
        expect(find.text('M2'), findsOneWidget);
        expect(find.text('TOUCHPAD'), findsOneWidget);

        // Open Quick Menu Drawer via ☰ menu trigger
        await tester.tap(find.text('☰'));
        await tester.pumpAndSettle();

        expect(find.text('CONTROLLER STUDIO'), findsOneWidget);
        expect(find.text('TAP OUTSIDE TO RESUME GAMEPAD'), findsOneWidget);
        expect(find.text('CONSOLES & ACTION'), findsOneWidget);
        expect(find.text('SIMULATORS (COMING SOON)'), findsOneWidget);
        expect(find.text('DEADZONE: 5%'), findsOneWidget);
        expect(find.text('OPACITY: 85%'), findsOneWidget);
        expect(find.text('HAPTICS: ON'), findsOneWidget);
        expect(find.text('GYRO: OFF'), findsOneWidget);

        // Toggle Haptics, Gyro, and Theme inside the drawer
        await tester.tap(find.text('HAPTICS: ON'));
        await tester.pumpAndSettle();
        expect(find.text('HAPTICS: OFF'), findsOneWidget);

        await tester.tap(find.text('GYRO: OFF'));
        await tester.pumpAndSettle();
        expect(find.text('GYRO: ON'), findsOneWidget);

        await tester.tap(find.text('DARK MODE'));
        await tester.pumpAndSettle();
        expect(find.text('LIGHT MODE'), findsOneWidget);

        // Drag Deadzone & Opacity sliders and verify live state updates
        final sliders = find.byType(Slider);
        expect(sliders, findsNWidgets(2));
        await tester.ensureVisible(sliders.first);
        await tester.drag(sliders.first, const Offset(80, 0));
        await tester.pumpAndSettle();
        expect(find.text('DEADZONE: 5%'), findsNothing);

        await tester.ensureVisible(sliders.last);
        await tester.drag(sliders.last, const Offset(-80, 0));
        await tester.pumpAndSettle();
        expect(find.text('OPACITY: 85%'), findsNothing);

        // Switch preset -> Xbox inside the drawer (updates underlying gamepad live)
        await tester.ensureVisible(find.text('Xbox'));
        await tester.tap(find.text('Xbox'));
        await tester.pumpAndSettle();
        expect(find.text('LT'), findsOneWidget);
        expect(find.text('RT'), findsOneWidget);

        // Dismiss drawer via dimmed backdrop tap
        await tester.tap(find.text('TAP OUTSIDE TO RESUME GAMEPAD'));
        await tester.pumpAndSettle();
        expect(find.text('CONTROLLER STUDIO'), findsNothing);

        // Re-open via ☰ and switch preset -> Switch inside the drawer
        await tester.tap(find.text('☰'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Switch'));
        await tester.pumpAndSettle();
        expect(find.text('ZL'), findsOneWidget);
        expect(find.text('ZR'), findsOneWidget);

        // Dismiss drawer via close ✕ button
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();
        expect(find.text('CONTROLLER STUDIO'), findsNothing);

        // Verify Nintendo physical diamond order: X top, A right, B bottom, Y left
        final xPos = tester.getCenter(find.text('X'));
        final aPos = tester.getCenter(find.text('A'));
        final bPos = tester.getCenter(find.text('B'));
        final yPos = tester.getCenter(find.text('Y'));
        expect(xPos.dy, lessThan(bPos.dy));
        expect(yPos.dx, lessThan(aPos.dx));

        // Re-open Quick Menu via Switch Home button & test EDIT HUD LAYOUT
        await tester.tap(find.byIcon(Icons.home_rounded));
        await tester.pumpAndSettle();
        expect(find.text('CONTROLLER STUDIO'), findsOneWidget);

        await tester.ensureVisible(find.text('EDIT HUD LAYOUT'));
        await tester.tap(find.text('EDIT HUD LAYOUT'));
        await tester.pumpAndSettle();
        expect(find.text('HUD EDIT'), findsOneWidget);

        await tester.tap(find.text('Larger'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('DONE'));
        await tester.pumpAndSettle();
        expect(find.text('HUD EDIT'), findsNothing);

        // Re-open and test PC PAIRING navigation back to ConnectScreen
        await tester.tap(find.text('☰'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('PC PAIRING (WI-FI / BT)'));
        await tester.tap(find.text('PC PAIRING (WI-FI / BT)'));
        await tester.pumpAndSettle();
        expect(find.text('Connect to PC'), findsOneWidget);
      }

      tester.view.reset();
    },
  );
}

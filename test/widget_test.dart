import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vcontrollers/main.dart';
import 'package:vcontrollers/screens/connect_screen.dart';
import 'package:vcontrollers/screens/gamepad_screen.dart';
import 'package:vcontrollers/screens/pc_keyboard_screen.dart';
import 'package:vcontrollers/services/connection_service.dart';
import 'package:vcontrollers/theme/gamepad_theme.dart';
import 'package:vcontrollers/theme/pc_suite_theme.dart';
import 'package:vcontrollers/widgets/pc_suite_parts.dart';

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
              '/gamepad': (_) =>
                  GamepadScreen(key: ValueKey('screen_$viewport')),
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

  testWidgets(
    'Trackpad, Mouse & Keyboard Suite (4 modes) renders cleanly in Dark & Light modes with zero overflow and working mode switches',
    (tester) async {
      for (final viewport in const [
        Size(667, 375),
        Size(852, 393),
        Size(932, 430),
      ]) {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey('suite_$viewport'),
            routes: {
              '/': (_) => const ConnectScreen(),
              '/gamepad': (_) =>
                  GamepadScreen(key: ValueKey('suite_gp_$viewport')),
            },
            initialRoute: '/gamepad',
          ),
        );
        await tester.pumpAndSettle();

        // Open Quick Menu Drawer and select Trackpad
        await tester.tap(find.text('☰'));
        await tester.pumpAndSettle();
        expect(find.text('PC INPUT & KEYBOARD SUITE'), findsOneWidget);
        await tester.tap(find.text('Trackpad'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        // Verify Mode 1: PC Trackpad & Mouse
        expect(find.text('LEFT CLICK (LMB)'), findsOneWidget);
        expect(find.text('MID'), findsOneWidget);
        expect(find.text('RIGHT CLICK (RMB)'), findsOneWidget);
        expect(find.text('SCROLL'), findsNothing);
        expect(find.text('DPI 1.2x'), findsOneWidget);

        // Cycle DPI
        await tester.tap(find.text('DPI 1.2x'));
        await tester.pumpAndSettle();
        expect(find.text('DPI 1.5x'), findsOneWidget);

        // Switch via top-bar KEYBOARD button -> Mode 2: Windows Mechanical Keyboard
        await tester.tap(find.text('KEYBOARD'));
        await tester.pumpAndSettle();
        expect(find.text('⌫ BKSP'), findsOneWidget);
        expect(find.text('↵ ENTER'), findsOneWidget);
        expect(find.text('TASK MGR'), findsOneWidget);

        // Toggle FN -> F1..F12 overlay
        await tester.tap(find.text('FN'));
        await tester.pumpAndSettle();
        expect(find.text('F1'), findsOneWidget);
        expect(find.text('F12'), findsOneWidget);

        // Switch OS via top-bar Win / macOS toggle -> Mode 3: macOS Keyboard
        await tester.tap(find.text('Win / macOS'));
        await tester.pumpAndSettle();
        expect(find.text('⌫ DELETE'), findsOneWidget);
        expect(find.text('⏎ RETURN'), findsOneWidget);
        expect(find.text('MISSION CTRL'), findsOneWidget);
        expect(find.text('⌘ CMD'), findsNWidgets(2));

        // Open Quick Menu -> switch to Light Mode and Hybrid WASD
        await tester.tap(find.text('☰'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('DARK MODE'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Hybrid WASD'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        // Verify Mode 4: Hybrid Gaming (WASD + Mouse Trackpad) in Light Mode
        expect(find.text('SHIFT (SPRINT)'), findsOneWidget);
        expect(find.text('CTRL (CROUCH)'), findsOneWidget);
        expect(find.text('SPACE (JUMP)'), findsOneWidget);
        expect(find.text('LMB (FIRE / CLICK)'), findsOneWidget);
        expect(find.text('RMB (ADS / MENU)'), findsOneWidget);

        // Switch back to Full KB via top-bar FULL KB button
        await tester.tap(find.text('FULL KB'));
        await tester.pumpAndSettle();
        expect(find.text('↵ ENTER'), findsOneWidget);
      }

      tester.view.reset();
    },
  );

  testWidgets(
    'Trackpad supports Portrait & Landscape in Light & Dark themes without overflow and gestures reach callbacks',
    (tester) async {
      for (final isDark in const [true, false]) {
        for (final viewport in const [
          Size(393, 852),
          Size(360, 780),
          Size(852, 393),
          Size(667, 375),
        ]) {
          SharedPreferences.setMockInitialValues(
              {'vcontrollers_ui_dark': isDark});
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            MaterialApp(
              key: ValueKey('tp_${isDark}_$viewport'),
              routes: {
                '/': (_) => const ConnectScreen(),
                '/gamepad': (_) => GamepadScreen(
                      key: ValueKey('tp_gp_${isDark}_$viewport'),
                      initialStyle: GamepadStyle.pcTrackpad,
                    ),
              },
              initialRoute: '/gamepad',
            ),
          );
          await tester.pumpAndSettle();

          final portrait = viewport.height > viewport.width;
          expect(find.text('MID'), findsOneWidget);
          expect(find.text('SCROLL'), findsNothing);
          expect(find.text('DPI 1.2x'), findsOneWidget);
          expect(find.text('KEYBOARD'), findsOneWidget);
          expect(find.text(portrait ? 'LMB (LEFT)' : 'LEFT CLICK (LMB)'),
              findsOneWidget);
          expect(find.text('◀ BACK'), portrait ? findsOneWidget : findsNothing);
          expect(
              find.text('WIN / ⌘'), portrait ? findsOneWidget : findsNothing);
          expect(find.text('FWD ▶'), portrait ? findsOneWidget : findsNothing);

          // Two-finger drag on trackpad must not throw.
          final pad = find.byType(PcMultiTouchTrackpad);
          expect(pad, findsOneWidget);
          final c = tester.getCenter(pad);
          final g1 = await tester.startGesture(c + const Offset(-10, 0));
          final g2 = await tester.startGesture(c + const Offset(10, 0));
          await g1.moveBy(const Offset(0, 20));
          await g2.moveBy(const Offset(0, 20));
          await g1.up();
          await g2.up();
          await tester.pumpAndSettle();
        }
      }

      tester.view.reset();
    },
  );

  testWidgets(
    'PcKeyboardScreen repeat keys do not double-send and sticky modifiers latch cleanly',
    (tester) async {
      final events = <(String, bool, Set<String>)>[];
      tester.view.physicalSize = const Size(852, 393);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: PcKeyboardScreen(
            config: PcSuiteScreenConfig(
              theme: GamepadTheme.playstationDark,
              hudOpacity: 1.0,
              status: (color: const Color(0xFF22C55E), label: 'KEYBOARD • LIVE'),
              onOpenMenu: () {},
              onSwitchStyle: (_) {},
            ),
            isMac: false,
            onKeyEvent: (key, pressed, mods) =>
                events.add((key, pressed, Set<String>.from(mods))),
            onShortcut: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Quick tap on SPACE (enableRepeat: true) must emit exactly 1 down + 1 up.
      await tester.tap(find.text('SPACE'));
      await tester.pumpAndSettle();
      expect(events.where((e) => e.$1 == 'SPACE').length, 2);
      expect(events.first.$2, isTrue);
      expect(events.last.$2, isFalse);

      events.clear();

      // Quick tap on SHIFT latches it ON without emitting pressed: false.
      await tester.tap(find.text('⇧ SHIFT'));
      await tester.pumpAndSettle();
      expect(events.length, 1);
      expect(events.first.$1, 'SHIFT');
      expect(events.first.$2, isTrue);
      expect(events.first.$3, {'SHIFT'});
      expect(find.text('A'), findsOneWidget);

      events.clear();

      // Tapping 'A' sends 'A' with SHIFT modifier, then auto-releases SHIFT.
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      expect(events.length, 3);
      expect((events[0].$1, events[0].$2), ('A', true));
      expect(events[0].$3, {'SHIFT'});
      expect((events[1].$1, events[1].$2), ('A', false));
      expect(events[1].$3, {'SHIFT'});
      expect((events[2].$1, events[2].$2), ('SHIFT', false));
      expect(events[2].$3, isEmpty);

      tester.view.reset();
    },
  );

  testWidgets(
    'PcMultiTouchTrackpad delivers smooth 1-finger move and 2-finger scroll without stray cursor jump on lift',
    (tester) async {
      final moves = <Offset>[];
      final scrolls = <Offset>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PcMultiTouchTrackpad(
                palette: PcSuiteTheme.dark,
                width: 400,
                height: 240,
                caption: 'TEST PAD',
                onMouseMove: (dx, dy) => moves.add(Offset(dx, dy)),
                onMouseButton: (_, __) {},
                onMouseScroll: (dx, dy) => scrolls.add(Offset(dx, dy)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pad = find.byType(PcMultiTouchTrackpad);
      final center = tester.getCenter(pad);

      // 1-finger drag emits cursor movement.
      final g = await tester.startGesture(center);
      await g.moveBy(const Offset(18, 6), timeStamp: const Duration(milliseconds: 16));
      await g.up(timeStamp: const Duration(milliseconds: 32));
      await tester.pumpAndSettle();
      expect(moves, isNotEmpty);

      moves.clear();
      scrolls.clear();

      // 2-finger vertical drag emits scroll (with horizontal axis-locked to 0)
      // and lifting 1 finger before the other must not emit stray mouse_move.
      final g1 = await tester.startGesture(center + const Offset(-12, 0));
      final g2 = await tester.startGesture(center + const Offset(12, 0));
      await g1.moveBy(const Offset(1, 24), timeStamp: const Duration(milliseconds: 16));
      await g2.moveBy(const Offset(1, 24), timeStamp: const Duration(milliseconds: 16));
      await g1.up(timeStamp: const Duration(milliseconds: 32));
      // Stray micro-move from remaining finger before lifting:
      await g2.moveBy(const Offset(4, 4), timeStamp: const Duration(milliseconds: 40));
      await g2.up(timeStamp: const Duration(milliseconds: 48));
      await tester.pumpAndSettle();

      expect(scrolls, isNotEmpty);
      expect(scrolls.every((s) => s.dx == 0.0), isTrue);
      expect(moves, isEmpty);
    },
  );

  testWidgets(
    'PcMultiTouchTrackpad supports 3-finger tap (Middle Click) and 3-finger swipes (Task View, Desktop, Switch App)',
    (tester) async {
      final buttons = <(MouseButton, bool)>[];
      final shortcuts = <List<String>>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PcMultiTouchTrackpad(
                palette: PcSuiteTheme.dark,
                width: 400,
                height: 240,
                caption: 'TEST PAD',
                onMouseMove: (_, __) {},
                onMouseButton: (btn, down) => buttons.add((btn, down)),
                onMouseScroll: (_, __) {},
                onShortcut: (keys) => shortcuts.add(keys),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final center = tester.getCenter(find.byType(PcMultiTouchTrackpad));

      // 3-Finger Tap -> Middle Click
      final t1 = await tester.startGesture(center + const Offset(-20, 0));
      final t2 = await tester.startGesture(center);
      final t3 = await tester.startGesture(center + const Offset(20, 0));
      await t1.up();
      await t2.up();
      await t3.up();
      await tester.pump(const Duration(milliseconds: 800));
      expect(buttons, [(MouseButton.middle, true), (MouseButton.middle, false)]);

      // 3-Finger Swipe Up -> Task View (META+TAB)
      final u1 = await tester.startGesture(center + const Offset(-20, 20));
      final u2 = await tester.startGesture(center + const Offset(0, 20));
      final u3 = await tester.startGesture(center + const Offset(20, 20));
      await u1.moveBy(const Offset(0, -60));
      await u2.moveBy(const Offset(0, -60));
      await u3.moveBy(const Offset(0, -60));
      await u1.up();
      await u2.up();
      await u3.up();
      await tester.pump(const Duration(milliseconds: 800));
      expect(shortcuts.last, ['META', 'TAB']);

      // 3-Finger Swipe Down -> Show Desktop (META+D)
      final d1 = await tester.startGesture(center + const Offset(-20, -20));
      final d2 = await tester.startGesture(center + const Offset(0, -20));
      final d3 = await tester.startGesture(center + const Offset(20, -20));
      await d1.moveBy(const Offset(0, 60));
      await d2.moveBy(const Offset(0, 60));
      await d3.moveBy(const Offset(0, 60));
      await d1.up();
      await d2.up();
      await d3.up();
      await tester.pump(const Duration(milliseconds: 800));
      expect(shortcuts.last, ['META', 'D']);

      // 3-Finger Swipe Right -> Switch App Next (ALT+TAB)
      final r1 = await tester.startGesture(center + const Offset(-30, -10));
      final r2 = await tester.startGesture(center + const Offset(-30, 0));
      final r3 = await tester.startGesture(center + const Offset(-30, 10));
      await r1.moveBy(const Offset(65, 0));
      await r2.moveBy(const Offset(65, 0));
      await r3.moveBy(const Offset(65, 0));
      await r1.up();
      await r2.up();
      await r3.up();
      await tester.pump(const Duration(milliseconds: 800));
      expect(shortcuts.last, ['ALT', 'TAB']);
    },
  );
}

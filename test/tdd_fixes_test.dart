import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vcontrollers/services/connection_service.dart';
import 'package:vcontrollers/theme/pc_suite_theme.dart';
import 'package:vcontrollers/widgets/pc_suite_parts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'switching from Bluetooth to WiFi invokes native Bluetooth disconnect before closing',
    () async {
      SharedPreferences.setMockInitialValues({});
      const btChannel = MethodChannel('com.example.vcontrollers/bluetooth');
      const btEvents = MethodChannel('com.example.vcontrollers/bluetooth_events');
      final calls = <String>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(btChannel, (call) async {
        calls.add(call.method);
        return true;
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(btEvents, (call) async => null);
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(btChannel, null);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(btEvents, null);
      });

      final service = ConnectionService.instance;
      await service.init();
      await service.connectBluetooth('AA:BB:CC:DD:EE:FF', deviceName: 'TestPC');
      calls.clear();

      // Switching to WiFi must close the active native Bluetooth socket.
      unawaited(service.connect('127.0.0.1', port: 1));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await service.disconnect();

      expect(calls, contains('disconnect'));
    },
  );

  testWidgets(
    '3-finger swipe does not display gesture HUD feedback when onShortcut is null',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PcMultiTouchTrackpad(
                palette: PcSuiteTheme.dark,
                width: 400,
                height: 240,
                caption: 'AIM PAD',
                onMouseMove: (_, __) {},
                onMouseButton: (_, __) {},
                onMouseScroll: (_, __) {},
                onShortcut: null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final center = tester.getCenter(find.byType(PcMultiTouchTrackpad));
      final u1 = await tester.startGesture(center + const Offset(-20, 20));
      final u2 = await tester.startGesture(center + const Offset(0, 20));
      final u3 = await tester.startGesture(center + const Offset(20, 20));
      await u1.moveBy(const Offset(0, -60));
      await u2.moveBy(const Offset(0, -60));
      await u3.moveBy(const Offset(0, -60));
      await u1.up();
      await u2.up();
      await u3.up();
      await tester.pump();

      expect(find.text('TASK VIEW'), findsNothing);
      expect(find.text('AIM PAD'), findsOneWidget);
    },
  );

  testWidgets(
    'slow 2-finger scroll with identical pointer timestamps does not inflate velocity into inertia',
    (tester) async {
      final scrolls = <Offset>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PcMultiTouchTrackpad(
                palette: PcSuiteTheme.dark,
                width: 400,
                height: 240,
                caption: 'SCROLL PAD',
                onMouseMove: (_, __) {},
                onMouseButton: (_, __) {},
                onMouseScroll: (dx, dy) => scrolls.add(Offset(dx, dy)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final center = tester.getCenter(find.byType(PcMultiTouchTrackpad));
      final g1 = await tester.startGesture(center + const Offset(-12, 0));
      final g2 = await tester.startGesture(center + const Offset(12, 0));
      // 14px over 200ms = 70 px/s (below 80 px/s inertia threshold, > 12px tap threshold).
      await g1.moveBy(
        const Offset(0, 7.0),
        timeStamp: const Duration(milliseconds: 100),
      );
      await g2.moveBy(
        const Offset(0, 7.0),
        timeStamp: const Duration(milliseconds: 100),
      );
      await g1.moveBy(
        const Offset(0, 7.0),
        timeStamp: const Duration(milliseconds: 200),
      );
      await g2.moveBy(
        const Offset(0, 7.0),
        timeStamp: const Duration(milliseconds: 200),
      );
      await g1.up(timeStamp: const Duration(milliseconds: 216));
      await g2.up(timeStamp: const Duration(milliseconds: 216));

      final countAtLift = scrolls.length;
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      expect(scrolls.length, countAtLift);
    },
  );
}

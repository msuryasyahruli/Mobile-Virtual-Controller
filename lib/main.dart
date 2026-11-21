import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/connect_screen.dart';
import 'screens/gamepad_screen.dart';
import 'services/connection_service.dart';

/// Entry point aplikasi WiFi Gamepad yang menginisialisasi SharedPreferences.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await ConnectionService.instance.init(prefs);
  runApp(const WiFiGamepadApp());
}

/// Root widget MaterialApp dengan tema gaming gelap dan konfigurasi rute aplikasi.
class WiFiGamepadApp extends StatelessWidget {
  /// Membuat [WiFiGamepadApp].
  const WiFiGamepadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiFi Gamepad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D9FF),
          secondary: Color(0xFFE94560),
          surface: Color(0xFF16213E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF16213E),
          elevation: 0,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const ConnectScreen(),
        '/gamepad': (_) => const GamepadScreen(),
      },
    );
  }
}

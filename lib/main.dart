import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/connect_screen.dart';
import 'screens/gamepad_screen.dart';
import 'services/connection_service.dart';
import 'theme/gamepad_theme.dart';

/// Entry point aplikasi VControllers yang menginisialisasi SharedPreferences.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await ConnectionService.instance.init(prefs);
  runApp(const VControllersApp());
}

/// Root widget MaterialApp dengan token desain konsisten dan routing '/' serta '/gamepad'.
class VControllersApp extends StatelessWidget {
  /// Membuat [VControllersApp].
  const VControllersApp({super.key});

  @override
  Widget build(BuildContext context) {
    const darkPreset = GamepadTheme.playstationDark;

    return MaterialApp(
      title: 'VControllers',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkPreset.chassisBg,
        colorScheme: ColorScheme.dark(
          primary: darkPreset.statusAccent,
          onPrimary: darkPreset.onStatusAccent,
          surface: darkPreset.buttonFill,
          onSurface: darkPreset.textPrimary,
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

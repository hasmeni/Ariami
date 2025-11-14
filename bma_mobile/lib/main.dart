import 'package:flutter/material.dart';
import 'utils/constants.dart';
import 'screens/welcome_screen.dart';
import 'screens/setup/tailscale_check_screen.dart';
import 'screens/setup/qr_scanner_screen.dart';
import 'screens/setup/permissions_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMA Mobile',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const WelcomeScreen(),
      routes: {
        '/setup/tailscale': (context) => const TailscaleCheckScreen(),
        '/setup/scanner': (context) => const QRScannerScreen(),
        '/setup/permissions': (context) => const PermissionsScreen(),
        '/main': (context) => const MainNavigationScreen(),
      },
    );
  }
}

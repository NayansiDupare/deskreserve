import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const DeskReserveApp());
}

class DeskReserveApp extends StatelessWidget {
  const DeskReserveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DeskReserve',
      theme: ThemeData(
        primaryColor: const Color(0xFF4A6CF7),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      ),
      home: const SplashScreen(), // 👈 ENTRY POINT
    );
  }
}

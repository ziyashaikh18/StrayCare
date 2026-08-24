import 'package:flutter/material.dart';
import 'screens/splashscreen.dart';

void main() {
  runApp(const StrayCareApp());
}

class StrayCareApp extends StatelessWidget {
  const StrayCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StrayCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}
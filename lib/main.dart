import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const CatGameApp());
}

class CatGameApp extends StatelessWidget {
  const CatGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pegue o Gato',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0288D1),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF050E1A),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}

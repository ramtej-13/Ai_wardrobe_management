import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AtelierApp(),
    ),
  );
}

class AtelierApp extends StatelessWidget {
  const AtelierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Wardrobe',
      debugShowCheckedModeBanner: false,
      theme: AtelierTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

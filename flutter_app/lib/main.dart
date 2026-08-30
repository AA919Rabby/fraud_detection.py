import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const FraudApp());
}

class FraudApp extends StatelessWidget {
  const FraudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fraud detection console',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
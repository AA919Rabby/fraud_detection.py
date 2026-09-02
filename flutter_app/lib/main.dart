import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
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
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? token;
  String? baseUrl;

  @override
  Widget build(BuildContext context) {
    if (token == null || baseUrl == null) {
      return AuthScreen(
        onLoggedIn: (t, url) => setState(() {
          token = t;
          baseUrl = url;
        }),
      );
    }
    return HomeScreen(
      token: token!,
      baseUrl: baseUrl!,
      onLogout: () => setState(() {
        token = null;
        baseUrl = null;
      }),
    );
  }
}
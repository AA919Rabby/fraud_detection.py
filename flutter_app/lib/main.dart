import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool checking = true;

  @override
  void initState() {
    super.initState();
    _loadSavedSession();
  }

  Future<void> _loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString("token");
      baseUrl = prefs.getString("baseUrl");
      checking = false;
    });
  }

  Future<void> _saveSession(String t, String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", t);
    await prefs.setString("baseUrl", url);
    setState(() {
      token = t;
      baseUrl = url;
    });
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("baseUrl");
    setState(() {
      token = null;
      baseUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0C29),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (token == null || baseUrl == null) {
      return AuthScreen(onLoggedIn: _saveSession);
    }
    return HomeScreen(
      token: token!,
      baseUrl: baseUrl!,
      onLogout: _clearSession,
    );
  }
}
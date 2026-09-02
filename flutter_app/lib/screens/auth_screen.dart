import 'package:flutter/material.dart';
import '../services/fraud_service.dart';
import '../widgets/gradient_button.dart';
import '../widgets/glass_card.dart';

enum _Mode { login, register, forgot, reset }

class AuthScreen extends StatefulWidget {
  final void Function(String token, String baseUrl) onLoggedIn;
  const AuthScreen({super.key, required this.onLoggedIn});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _Mode mode = _Mode.login;

  final baseUrlController =
      TextEditingController(text: "https://fraud-detection-py.onrender.com");
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final codeController = TextEditingController();
  final newPasswordController = TextEditingController();

  bool loading = false;
  String? error;
  String? info;

  FraudService get _service =>
      FraudService(baseUrl: baseUrlController.text.trim());

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7F5AF0), width: 1.4),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Future<void> _submit() async {
    setState(() { loading = true; error = null; info = null; });
    try {
      switch (mode) {
        case _Mode.login:
          final token = await _service.login(
            email: emailController.text.trim(),
            password: passwordController.text,
          );
          widget.onLoggedIn(token, baseUrlController.text.trim());
          break;

        case _Mode.register:
          await _service.register(
            email: emailController.text.trim(),
            password: passwordController.text,
          );
          setState(() {
            info = "Account created — you can log in now.";
            mode = _Mode.login;
          });
          break;

        case _Mode.forgot:
          final res = await _service.forgotPassword(email: emailController.text.trim());
          setState(() {
            info = res["message"]?.toString() ?? "Check your email for a code.";
            mode = _Mode.reset;
          });
          break;

        case _Mode.reset:
          final res = await _service.resetPassword(
            email: emailController.text.trim(),
            code: codeController.text.trim(),
            newPassword: newPasswordController.text,
          );
          setState(() {
            info = res["message"]?.toString() ?? "Password reset — you can log in now.";
            mode = _Mode.login;
          });
          break;
      }
    } catch (e) {
      setState(() => error = e.toString().replaceFirst("Exception: ", ""));
    }
    setState(() => loading = false);
  }

  String get _title {
    switch (mode) {
      case _Mode.login: return "Log in";
      case _Mode.register: return "Create account";
      case _Mode.forgot: return "Forgot password";
      case _Mode.reset: return "Reset password";
    }
  }

  String get _buttonLabel {
    switch (mode) {
      case _Mode.login: return "Log in";
      case _Mode.register: return "Create account";
      case _Mode.forgot: return "Send reset code";
      case _Mode.reset: return "Reset password";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF7F5AF0), Color(0xFF2CB1FF)],
                      ).createShader(bounds),
                      child: const Text(
                        "Fraud detection console",
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_title, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                    const SizedBox(height: 24),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: baseUrlController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _dec("API base URL"),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _dec("Email"),
                          ),
                          if (mode == _Mode.login || mode == _Mode.register) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: _dec("Password"),
                            ),
                          ],
                          if (mode == _Mode.reset) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: codeController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _dec("6-digit code from email"),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: newPasswordController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: _dec("New password"),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    GradientButton(label: _buttonLabel, onPressed: loading ? null : _submit, loading: loading),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(error!, style: const TextStyle(color: Color(0xFFFF8080), fontSize: 13)),
                      ),
                    if (info != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(info!, style: const TextStyle(color: Color(0xFF6FE3B4), fontSize: 13)),
                      ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      children: [
                        if (mode != _Mode.login)
                          TextButton(
                            onPressed: loading ? null : () => setState(() { mode = _Mode.login; error = null; info = null; }),
                            child: const Text("Log in", style: TextStyle(color: Colors.white70)),
                          ),
                        if (mode != _Mode.register)
                          TextButton(
                            onPressed: loading ? null : () => setState(() { mode = _Mode.register; error = null; info = null; }),
                            child: const Text("Create account", style: TextStyle(color: Colors.white70)),
                          ),
                        if (mode != _Mode.forgot && mode != _Mode.reset)
                          TextButton(
                            onPressed: loading ? null : () => setState(() { mode = _Mode.forgot; error = null; info = null; }),
                            child: const Text("Forgot password?", style: TextStyle(color: Colors.white70)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
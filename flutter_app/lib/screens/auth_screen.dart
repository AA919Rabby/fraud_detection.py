import 'package:flutter/material.dart';
import '../services/fraud_service.dart';
import '../widgets/gradient_button.dart';
import '../widgets/glass_card.dart';

enum _Mode { login, register, forgot, reset }

class AuthScreen extends StatefulWidget {
  final void Function(String token, String baseUrl) onLoggedIn;

  const AuthScreen({
    super.key,
    required this.onLoggedIn,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _Mode mode = _Mode.login;

  final TextEditingController baseUrlController = TextEditingController(
    text: "https://fraud-detection-py.onrender.com",
  );

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController =
      TextEditingController();

  bool loading = false;
  String? error;
  String? info;

  FraudService get _service {
    return FraudService(
      baseUrl: baseUrlController.text.trim(),
    );
  }

  // ------------------------------------------------------------
  // INPUT DECORATION
  // ------------------------------------------------------------

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.white70,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF7F5AF0),
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.4,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // ------------------------------------------------------------
  // VALIDATION
  // ------------------------------------------------------------

  String? _validate() {
    final baseUrl = baseUrlController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (baseUrl.isEmpty) {
      return "API base URL is required.";
    }

    final uri = Uri.tryParse(baseUrl);

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != "http" && uri.scheme != "https") ||
        uri.host.isEmpty) {
      return "Please enter a valid API base URL.";
    }

    switch (mode) {
      case _Mode.login:
        if (email.isEmpty) {
          return "Please enter your email.";
        }

        if (!_isValidEmail(email)) {
          return "Please enter a valid email address.";
        }

        if (password.isEmpty) {
          return "Please enter your password.";
        }

        return null;

      case _Mode.register:
        if (email.isEmpty) {
          return "Please enter your email.";
        }

        if (!_isValidEmail(email)) {
          return "Please enter a valid email address.";
        }

        if (password.isEmpty) {
          return "Please enter a password.";
        }

        if (password.length < 6) {
          return "Password must be at least 6 characters.";
        }

        return null;

      case _Mode.forgot:
        if (email.isEmpty) {
          return "Please enter your email.";
        }

        if (!_isValidEmail(email)) {
          return "Please enter a valid email address.";
        }

        return null;

      case _Mode.reset:
        if (email.isEmpty) {
          return "Please enter your email.";
        }

        if (!_isValidEmail(email)) {
          return "Please enter a valid email address.";
        }

        if (codeController.text.trim().isEmpty) {
          return "Please enter the reset code.";
        }

        if (newPasswordController.text.isEmpty) {
          return "Please enter your new password.";
        }

        if (newPasswordController.text.length < 6) {
          return "New password must be at least 6 characters.";
        }

        return null;
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

  // ------------------------------------------------------------
  // SUBMIT
  // ------------------------------------------------------------

  Future<void> _submit() async {
    // IMPORTANT:
    // Validate BEFORE showing the loading spinner.
    final validationError = _validate();

    if (validationError != null) {
      setState(() {
        error = validationError;
        info = null;
        loading = false;
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
      info = null;
    });

    try {
      switch (mode) {
        // ------------------------------------------------------
        // LOGIN
        // ------------------------------------------------------

        case _Mode.login:
          final token = await _service.login(
            email: emailController.text.trim(),
            password: passwordController.text,
          );

          if (!mounted) return;

          widget.onLoggedIn(
            token,
            baseUrlController.text.trim(),
          );

          break;

        // ------------------------------------------------------
        // REGISTER
        // ------------------------------------------------------

        case _Mode.register:
          await _service.register(
            email: emailController.text.trim(),
            password: passwordController.text,
          );

          if (!mounted) return;

          setState(() {
            info = "Account created — you can log in now.";
            mode = _Mode.login;
            passwordController.clear();
          });

          break;

        // ------------------------------------------------------
        // FORGOT PASSWORD
        // ------------------------------------------------------

        case _Mode.forgot:
          final res = await _service.forgotPassword(
            email: emailController.text.trim(),
          );

          if (!mounted) return;

          setState(() {
            info = res["message"]?.toString() ??
                "Check your email for a reset code.";

            mode = _Mode.reset;
          });

          break;

        // ------------------------------------------------------
        // RESET PASSWORD
        // ------------------------------------------------------

        case _Mode.reset:
          final res = await _service.resetPassword(
            email: emailController.text.trim(),
            code: codeController.text.trim(),
            newPassword: newPasswordController.text,
          );

          if (!mounted) return;

          setState(() {
            info = res["message"]?.toString() ??
                "Password reset successfully — you can log in now.";

            mode = _Mode.login;

            codeController.clear();
            newPasswordController.clear();
            passwordController.clear();
          });

          break;
      }
    } catch (e) {
      if (!mounted) return;

      String message = e.toString();

      if (message.startsWith("Exception: ")) {
        message = message.substring("Exception: ".length);
      }

      setState(() {
        error = message;
      });
    } finally {
      // Never leave the button stuck on loading.
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // MODE
  // ------------------------------------------------------------

  String get _title {
    switch (mode) {
      case _Mode.login:
        return "Log in";

      case _Mode.register:
        return "Create account";

      case _Mode.forgot:
        return "Forgot password";

      case _Mode.reset:
        return "Reset password";
    }
  }

  String get _buttonLabel {
    switch (mode) {
      case _Mode.login:
        return "Log in";

      case _Mode.register:
        return "Create account";

      case _Mode.forgot:
        return "Send reset code";

      case _Mode.reset:
        return "Reset password";
    }
  }

  // ------------------------------------------------------------
  // CHANGE MODE
  // ------------------------------------------------------------

  void _changeMode(_Mode newMode) {
    if (loading) return;

    setState(() {
      mode = newMode;
      error = null;
      info = null;
    });
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    baseUrlController.dispose();
    emailController.dispose();
    passwordController.dispose();
    codeController.dispose();
    newPasswordController.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29),
              Color(0xFF302B63),
              Color(0xFF24243E),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 460,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --------------------------------------------------
                    // TITLE
                    // --------------------------------------------------

                    ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          colors: [
                            Color(0xFF7F5AF0),
                            Color(0xFF2CB1FF),
                          ],
                        ).createShader(bounds);
                      },
                      child: const Text(
                        "Fraud detection console",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _title,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --------------------------------------------------
                    // FORM
                    // --------------------------------------------------

                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // API URL
                          TextField(
                            controller: baseUrlController,
                            enabled: !loading,
                            keyboardType: TextInputType.url,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            decoration: _dec("API base URL"),
                          ),

                          const SizedBox(height: 12),

                          // EMAIL
                          TextField(
                            controller: emailController,
                            enabled: !loading,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            decoration: _dec("Email"),
                          ),

                          // LOGIN / REGISTER PASSWORD
                          if (mode == _Mode.login ||
                              mode == _Mode.register) ...[
                            const SizedBox(height: 12),

                            TextField(
                              controller: passwordController,
                              enabled: !loading,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                              decoration: _dec("Password"),
                              onSubmitted: (_) {
                                if (!loading) {
                                  _submit();
                                }
                              },
                            ),
                          ],

                          // RESET PASSWORD FIELDS
                          if (mode == _Mode.reset) ...[
                            const SizedBox(height: 12),

                            TextField(
                              controller: codeController,
                              enabled: !loading,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                              decoration: _dec(
                                "6-digit code from email",
                              ),
                            ),

                            const SizedBox(height: 12),

                            TextField(
                              controller: newPasswordController,
                              enabled: !loading,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                              decoration: _dec("New password"),
                              onSubmitted: (_) {
                                if (!loading) {
                                  _submit();
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // --------------------------------------------------
                    // BUTTON
                    // --------------------------------------------------

                    GradientButton(
                      label: _buttonLabel,
                      onPressed: loading ? null : _submit,
                      loading: loading,
                    ),

                    // --------------------------------------------------
                    // ERROR
                    // --------------------------------------------------

                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 14,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.redAccent.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Color(0xFFFF8080),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  error!,
                                  style: const TextStyle(
                                    color: Color(0xFFFF8080),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // --------------------------------------------------
                    // INFO
                    // --------------------------------------------------

                    if (info != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 14,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6FE3B4)
                                .withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF6FE3B4)
                                  .withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Color(0xFF6FE3B4),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  info!,
                                  style: const TextStyle(
                                    color: Color(0xFF6FE3B4),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // --------------------------------------------------
                    // NAVIGATION BUTTONS
                    // --------------------------------------------------

                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        // Login
                        if (mode != _Mode.login)
                          TextButton(
                            onPressed: loading
                                ? null
                                : () => _changeMode(_Mode.login),
                            child: const Text(
                              "Log in",
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ),

                        // Register
                        if (mode != _Mode.register)
                          TextButton(
                            onPressed: loading
                                ? null
                                : () => _changeMode(
                                      _Mode.register,
                                    ),
                            child: const Text(
                              "Create account",
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ),

                        // Forgot password
                        if (mode != _Mode.forgot &&
                            mode != _Mode.reset)
                          TextButton(
                            onPressed: loading
                                ? null
                                : () => _changeMode(
                                      _Mode.forgot,
                                    ),
                            child: const Text(
                              "Forgot password?",
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
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

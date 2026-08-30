import 'package:flutter/material.dart';
import '../services/fraud_service.dart';
import '../widgets/gradient_button.dart';
import '../widgets/glass_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0;
  final baseUrlController =
      TextEditingController(text: "https://fraud-detection-py.onrender.com");

  final tabs = const ["Health", "Check", "History", "Stats"];

  FraudService get _service => FraudService(
        baseUrl: baseUrlController.text.trim(),
      );

  InputDecoration _fieldDecoration(String label) => InputDecoration(
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
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF7F5AF0), Color(0xFF2CB1FF)],
                      ).createShader(bounds),
                      child: const Text(
                        "Fraud detection console",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Live testing UI for your deployed API",
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    GlassCard(
                      child: TextField(
                        controller: baseUrlController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _fieldDecoration("API base URL"),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: List.generate(tabs.length, (i) {
                        final active = selectedTab == i;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedTab = i),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: active
                                    ? const LinearGradient(
                                        colors: [Color(0xFF7F5AF0), Color(0xFF2CB1FF)])
                                    : null,
                                color: active ? null : Colors.white.withOpacity(0.05),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                tabs[i],
                                style: TextStyle(
                                  color: active ? Colors.white : Colors.white60,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    GlassCard(
                      child: IndexedStack(
                        index: selectedTab,
                        children: [
                          _HealthTab(getService: () => _service),
                          _CheckTab(getService: () => _service, fieldDecoration: _fieldDecoration),
                          _HistoryTab(getService: () => _service),
                          _StatsTab(getService: () => _service),
                        ],
                      ),
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

Widget _resultBox(String? result, String? error) {
  if (error != null) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
      ),
      child: Text(error, style: const TextStyle(color: Color(0xFFFF8080))),
    );
  }
  if (result == null) return const SizedBox.shrink();
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(top: 16),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.3),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
    ),
    child: SelectableText(
      result,
      style: const TextStyle(color: Color(0xFF6FE3B4), fontFamily: "monospace", fontSize: 13),
    ),
  );
}

class _HealthTab extends StatefulWidget {
  final FraudService Function() getService;
  const _HealthTab({required this.getService});
  @override
  State<_HealthTab> createState() => _HealthTabState();
}

class _HealthTabState extends State<_HealthTab> {
  String? result;
  String? error;
  bool loading = false;

  Future<void> _run() async {
    setState(() { loading = true; error = null; result = null; });
    try {
      final res = await widget.getService().health();
      setState(() => result = res.toString());
    } catch (e) {
      setState(() => error = e.toString());
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GradientButton(label: "Check /health", onPressed: loading ? null : _run, loading: loading),
        _resultBox(result, error),
      ],
    );
  }
}

class _CheckTab extends StatefulWidget {
  final FraudService Function() getService;
  final InputDecoration Function(String) fieldDecoration;
  const _CheckTab({required this.getService, required this.fieldDecoration});
  @override
  State<_CheckTab> createState() => _CheckTabState();
}

class _CheckTabState extends State<_CheckTab> {
  final amount = TextEditingController(text: "500");
  final hour = TextEditingController(text: "14");
  final txns = TextEditingController(text: "1");
  final device = TextEditingController(text: "0");
  final age = TextEditingController(text: "730");
  String? result;
  String? error;
  bool loading = false;

  Future<void> _run() async {
    setState(() { loading = true; error = null; result = null; });
    try {
      final res = await widget.getService().checkTransaction(
        amount: double.parse(amount.text),
        hourOfDay: double.parse(hour.text),
        transactionsLastHour: int.parse(txns.text),
        isNewDevice: int.parse(device.text),
        accountAgeDays: double.parse(age.text),
      );
      setState(() => result = res.toString());
    } catch (e) {
      setState(() => error = e.toString());
    }
    setState(() => loading = false);
  }

  Widget _field(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          style: const TextStyle(color: Colors.white),
          decoration: widget.fieldDecoration(label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(amount, "amount"),
        _field(hour, "hour_of_day"),
        _field(txns, "transactions_last_hour"),
        _field(device, "is_new_device (0/1)"),
        _field(age, "account_age_days"),
        GradientButton(label: "POST /check-transaction", onPressed: loading ? null : _run, loading: loading),
        _resultBox(result, error),
      ],
    );
  }
}

class _HistoryTab extends StatefulWidget {
  final FraudService Function() getService;
  const _HistoryTab({required this.getService});
  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  String? result;
  String? error;
  bool loading = false;

  Future<void> _run() async {
    setState(() { loading = true; error = null; result = null; });
    try {
      final res = await widget.getService().getHistory();
      setState(() => result = res.toString());
    } catch (e) {
      setState(() => error = e.toString());
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GradientButton(label: "GET /history", onPressed: loading ? null : _run, loading: loading),
        _resultBox(result, error),
      ],
    );
  }
}

class _StatsTab extends StatefulWidget {
  final FraudService Function() getService;
  const _StatsTab({required this.getService});
  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  String? result;
  String? error;
  bool loading = false;

  Future<void> _run() async {
    setState(() { loading = true; error = null; result = null; });
    try {
      final res = await widget.getService().getStats();
      setState(() => result = res.toString());
    } catch (e) {
      setState(() => error = e.toString());
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GradientButton(label: "GET /stats", onPressed: loading ? null : _run, loading: loading),
        _resultBox(result, error),
      ],
    );
  }
}
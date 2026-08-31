import 'dart:convert';
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
                      "Live testing UI deployed API",
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

// ───────────────────────── shared helpers ─────────────────────────

Color _riskColor(String? level) {
  switch ((level ?? "").toUpperCase()) {
    case "HIGH":
      return const Color(0xFFFF5F6D);
    case "MEDIUM":
      return const Color(0xFFFFC371);
    case "LOW":
      return const Color(0xFF6FE3B4);
    default:
      return Colors.white54;
  }
}

String _fmtNum(dynamic v) {
  if (v == null) return "—";
  if (v is num) {
    return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
  }
  return v.toString();
}

String _fmtDate(dynamic raw) {
  if (raw == null) return "—";
  try {
    final dt = DateTime.parse(raw.toString()).toLocal();
    final h = dt.hour.toString().padLeft(2, "0");
    final m = dt.minute.toString().padLeft(2, "0");
    return "${dt.year}-${dt.month.toString().padLeft(2, "0")}-${dt.day.toString().padLeft(2, "0")} $h:$m";
  } catch (_) {
    return raw.toString();
  }
}

Widget _errorBox(String error) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(top: 16),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.withOpacity(0.4)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, color: Color(0xFFFF8080), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(error, style: const TextStyle(color: Color(0xFFFF8080), fontSize: 13)),
        ),
      ],
    ),
  );
}

Widget _statChip(String label, String value, {Color? color}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color ?? Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      ],
    ),
  );
}

// A small labeled key/value row, used inside detail cards (Postman-like field list)
Widget _kv(String label, String value, {Color? valueColor}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: "monospace",
            ),
          ),
        ),
      ],
    ),
  );
}

// ───────────────────────── health tab ─────────────────────────

class _HealthTab extends StatefulWidget {
  final FraudService Function() getService;
  const _HealthTab({required this.getService});
  @override
  State<_HealthTab> createState() => _HealthTabState();
}

class _HealthTabState extends State<_HealthTab> {
  Map<String, dynamic>? result;
  String? error;
  bool loading = false;

  Future<void> _run() async {
    setState(() { loading = true; error = null; result = null; });
    try {
      final res = await widget.getService().health();
      setState(() => result = res);
    } catch (e) {
      setState(() => error = e.toString());
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final healthy = result?["status"] == "healthy";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GradientButton(label: "Check /health", onPressed: loading ? null : _run, loading: loading),
        if (error != null) _errorBox(error!),
        if (result != null)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (healthy ? const Color(0xFF6FE3B4) : Colors.red).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: (healthy ? const Color(0xFF6FE3B4) : Colors.red).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(healthy ? Icons.check_circle : Icons.error,
                    color: healthy ? const Color(0xFF6FE3B4) : Colors.red, size: 20),
                const SizedBox(width: 10),
                Text(
                  healthy ? "Service is healthy" : "Service reported an issue",
                  style: TextStyle(
                    color: healthy ? const Color(0xFF6FE3B4) : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ───────────────────────── check tab ─────────────────────────

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
  Map<String, dynamic>? result;
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
      setState(() => result = res);
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
    final riskLevel = result?["risk_level"] as String?;
    final probability = (result?["fraud_probability"] as num?)?.toDouble() ?? 0;
    final isFraud = result?["is_fraud"] == true;
    final color = _riskColor(riskLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(amount, "amount"),
        _field(hour, "hour_of_day"),
        _field(txns, "transactions_last_hour"),
        _field(device, "is_new_device (0/1)"),
        _field(age, "account_age_days"),
        GradientButton(label: "POST /check-transaction", onPressed: loading ? null : _run, loading: loading),
        if (error != null) _errorBox(error!),
        if (result != null)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        riskLevel ?? "—",
                        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                    const Spacer(),
                    Icon(isFraud ? Icons.gpp_bad : Icons.verified_user, color: color, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      isFraud ? "Flagged as fraud" : "Looks legitimate",
                      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Fraud probability: ${(probability * 100).toStringAsFixed(1)}%",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: probability.clamp(0, 1).toDouble(),
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: Colors.white.withOpacity(0.08)),
                const SizedBox(height: 10),
                _kv("Transaction ID", "#${result?["id"] ?? "—"}"),
              ],
            ),
          ),
      ],
    );
  }
}

// ───────────────────────── history tab ─────────────────────────

class _HistoryTab extends StatefulWidget {
  final FraudService Function() getService;
  const _HistoryTab({required this.getService});
  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  List<dynamic>? result;
  String? error;
  bool loading = false;

  Future<void> _run() async {
    setState(() { loading = true; error = null; result = null; });
    try {
      final res = await widget.getService().getHistory();
      setState(() => result = res);
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
        if (error != null) _errorBox(error!),
        if (result != null && result!.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text("No transactions logged yet.", style: TextStyle(color: Colors.white54)),
          ),
        if (result != null)
          ...result!.map((raw) {
            final item = raw as Map<String, dynamic>;
            final color = _riskColor(item["risk_level"] as String?);
            final isFraud = item["is_fraud"] == true;
            return Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Text("#${item["id"]}",
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item["risk_level"] ?? "—",
                          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(height: 1, color: Colors.white.withOpacity(0.06)),
                  const SizedBox(height: 8),
                  _kv("Amount", "Tk ${_fmtNum(item["amount"])}"),
                  _kv("Hour of day", _fmtNum(item["hour_of_day"])),
                  _kv("Txns last hour", _fmtNum(item["transactions_last_hour"])),
                  _kv("New device", item["is_new_device"] == 1 ? "Yes" : "No"),
                  _kv("Account age (days)", _fmtNum(item["account_age_days"])),
                  _kv("Fraud probability",
                      "${(((item["fraud_probability"] as num?) ?? 0) * 100).toStringAsFixed(1)}%"),
                  _kv("Flagged fraud", isFraud ? "Yes" : "No", valueColor: isFraud ? color : null),
                  _kv("Logged at", _fmtDate(item["created_at"])),
                ],
              ),
            );
          }),
      ],
    );
  }
}

// ───────────────────────── stats tab ─────────────────────────

class _StatsTab extends StatefulWidget {
  final FraudService Function() getService;
  const _StatsTab({required this.getService});
  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  Map<String, dynamic>? result;
  String? error;
  bool loading = false;

  Future<void> _run() async {
    setState(() { loading = true; error = null; result = null; });
    try {
      final res = await widget.getService().getStats();
      setState(() => result = res);
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
        if (error != null) _errorBox(error!),
        if (result != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _statChip("Total checked", _fmtNum(result!["total_checked"])),
                _statChip("Fraud detected", _fmtNum(result!["fraud_detected"]),
                    color: const Color(0xFFFF5F6D)),
                _statChip(
                  "Fraud rate",
                  "${(((result!["fraud_rate"] as num?) ?? 0) * 100).toStringAsFixed(1)}%",
                  color: const Color(0xFFFFC371),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
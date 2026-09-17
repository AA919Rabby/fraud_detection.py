import 'package:flutter/material.dart';
import '../services/fraud_service.dart';
import '../widgets/gradient_button.dart';
import '../widgets/glass_card.dart';

class HomeScreen extends StatefulWidget {
  final String token;
  final String baseUrl;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.token,
    required this.baseUrl,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0;

  final tabs = const [
    "Health",
    "Check",
    "History",
    "Stats",
  ];

  FraudService get _service => FraudService(
        baseUrl: widget.baseUrl,
        token: widget.token,
      );

  InputDecoration _fieldDecoration(String label) {
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
                maxWidth: 720,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // HEADER
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ShaderMask(
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
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: widget.onLogout,
                          icon: const Icon(
                            Icons.logout,
                            size: 16,
                            color: Colors.white54,
                          ),
                          label: const Text(
                            "Log out",
                            style: TextStyle(
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "Logged in · live testing UI for your deployed API",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // TABS
                    Row(
                      children: List.generate(
                        tabs.length,
                        (i) {
                          final active = selectedTab == i;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedTab = i;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: active
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF7F5AF0),
                                            Color(0xFF2CB1FF),
                                          ],
                                        )
                                      : null,
                                  color: active
                                      ? null
                                      : Colors.white.withOpacity(0.05),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  tabs[i],
                                  style: TextStyle(
                                    color: active
                                        ? Colors.white
                                        : Colors.white60,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // CONTENT
                    GlassCard(
                      child: IndexedStack(
                        index: selectedTab,
                        children: [
                          _HealthTab(
                            getService: () => _service,
                          ),
                          _CheckTab(
                            getService: () => _service,
                            fieldDecoration: _fieldDecoration,
                          ),
                          _HistoryTab(
                            getService: () => _service,
                          ),
                          _StatsTab(
                            getService: () => _service,
                          ),
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

// ============================================================
// SHARED HELPERS
// ============================================================

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

String _fmtNum(dynamic value) {
  if (value == null) {
    return "—";
  }

  if (value is num) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  return value.toString();
}

String _fmtDate(dynamic raw) {
  if (raw == null) {
    return "—";
  }

  try {
    final dt = DateTime.parse(
      raw.toString(),
    ).toLocal();

    final year = dt.year.toString();
    final month = dt.month.toString().padLeft(2, "0");
    final day = dt.day.toString().padLeft(2, "0");
    final hour = dt.hour.toString().padLeft(2, "0");
    final minute = dt.minute.toString().padLeft(2, "0");

    return "$year-$month-$day $hour:$minute";
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
      border: Border.all(
        color: Colors.red.withOpacity(0.4),
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
            error,
            style: const TextStyle(
              color: Color(0xFFFF8080),
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _statChip(
  String label,
  String value, {
  Color? color,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 10,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ],
    ),
  );
}

Widget _kv(
  String label,
  String value, {
  Color? valueColor,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(
      vertical: 5,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
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

// ============================================================
// HEALTH TAB
// ============================================================

class _HealthTab extends StatefulWidget {
  final FraudService Function() getService;

  const _HealthTab({
    required this.getService,
  });

  @override
  State<_HealthTab> createState() => _HealthTabState();
}

class _HealthTabState extends State<_HealthTab> {
  Map<String, dynamic>? result;
  String? error;
  bool loading = false;

  Future<void> _run() async {
    setState(() {
      loading = true;
      error = null;
      result = null;
    });

    try {
      final res = await widget.getService().health();

      if (!mounted) return;

      setState(() {
        result = res;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthy = result?["status"] == "healthy";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GradientButton(
          label: "Check /health",
          onPressed: loading ? null : _run,
          loading: loading,
        ),

        if (error != null) _errorBox(error!),

        if (result != null)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (healthy
                      ? const Color(0xFF6FE3B4)
                      : Colors.red)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (healthy
                        ? const Color(0xFF6FE3B4)
                        : Colors.red)
                    .withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  healthy
                      ? Icons.check_circle
                      : Icons.error,
                  color: healthy
                      ? const Color(0xFF6FE3B4)
                      : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  healthy
                      ? "Service is healthy"
                      : "Service reported an issue",
                  style: TextStyle(
                    color: healthy
                        ? const Color(0xFF6FE3B4)
                        : Colors.red,
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

// ============================================================
// CHECK TAB
// ============================================================

class _CheckTab extends StatefulWidget {
  final FraudService Function() getService;
  final InputDecoration Function(String) fieldDecoration;

  const _CheckTab({
    required this.getService,
    required this.fieldDecoration,
  });

  @override
  State<_CheckTab> createState() => _CheckTabState();
}

class _CheckTabState extends State<_CheckTab> {
  final TextEditingController amount =
      TextEditingController(text: "500");

  final TextEditingController hour =
      TextEditingController(text: "14");

  final TextEditingController txns =
      TextEditingController(text: "1");

  final TextEditingController age =
      TextEditingController(text: "730");

  int isNewDevice = 0;

  Map<String, dynamic>? result;

  String? error;

  bool loading = false;

  // ----------------------------------------------------------
  // THIS WAS MISSING IN YOUR CODE
  // ----------------------------------------------------------

  Widget _field(
    TextEditingController controller,
    String label,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: TextField(
        controller: controller,
        enabled: !loading,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
        ),
        style: const TextStyle(
          color: Colors.white,
        ),
        decoration: widget.fieldDecoration(
          label,
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // DEVICE FIELD
  // ----------------------------------------------------------

  Widget _deviceField() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: DropdownButtonFormField<int>(
        value: isNewDevice,
        dropdownColor: const Color(0xFF302B63),
        style: const TextStyle(
          color: Colors.white,
        ),
        decoration: widget.fieldDecoration(
          "is_new_device",
        ),
        items: const [
          DropdownMenuItem(
            value: 0,
            child: Text(
              "0 — Existing device",
            ),
          ),
          DropdownMenuItem(
            value: 1,
            child: Text(
              "1 — New device",
            ),
          ),
        ],
        onChanged: loading
            ? null
            : (value) {
                if (value != null) {
                  setState(() {
                    isNewDevice = value;
                  });
                }
              },
      ),
    );
  }

  // ----------------------------------------------------------
  // VALIDATION
  // ----------------------------------------------------------

  String? _validate() {
    if (amount.text.trim().isEmpty) {
      return "Please enter an amount.";
    }

    if (hour.text.trim().isEmpty) {
      return "Please enter the hour of day.";
    }

    if (txns.text.trim().isEmpty) {
      return "Please enter transactions in the last hour.";
    }

    if (age.text.trim().isEmpty) {
      return "Please enter the account age.";
    }

    final parsedAmount = double.tryParse(
      amount.text.trim(),
    );

    if (parsedAmount == null) {
      return "Amount must be a valid number.";
    }

    if (parsedAmount < 0) {
      return "Amount cannot be negative.";
    }

    final parsedHour = double.tryParse(
      hour.text.trim(),
    );

    if (parsedHour == null) {
      return "Hour of day must be a valid number.";
    }

    if (parsedHour < 0 || parsedHour > 23) {
      return "Hour of day must be between 0 and 23.";
    }

    final parsedTxns = int.tryParse(
      txns.text.trim(),
    );

    if (parsedTxns == null) {
      return "Transactions last hour must be a whole number.";
    }

    if (parsedTxns < 0) {
      return "Transactions last hour cannot be negative.";
    }

    final parsedAge = double.tryParse(
      age.text.trim(),
    );

    if (parsedAge == null) {
      return "Account age must be a valid number.";
    }

    if (parsedAge < 0) {
      return "Account age cannot be negative.";
    }

    return null;
  }

  // ----------------------------------------------------------
  // RUN CHECK
  // ----------------------------------------------------------

  Future<void> _run() async {
    final validationError = _validate();

    if (validationError != null) {
      setState(() {
        error = validationError;
        result = null;
        loading = false;
      });

      return;
    }

    setState(() {
      loading = true;
      error = null;
      result = null;
    });

    try {
      final res = await widget.getService().checkTransaction(
            amount: double.parse(
              amount.text.trim(),
            ),
            hourOfDay: double.parse(
              hour.text.trim(),
            ),
            transactionsLastHour: int.parse(
              txns.text.trim(),
            ),
            isNewDevice: isNewDevice,
            accountAgeDays: double.parse(
              age.text.trim(),
            ),
          );

      if (!mounted) return;

      setState(() {
        result = res;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst(
              "Exception: ",
              "",
            );
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    amount.dispose();
    hour.dispose();
    txns.dispose();
    age.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final riskLevel = result?["risk_level"] as String?;

    final probability =
        (result?["fraud_probability"] as num?)
                ?.toDouble() ??
            0;

    final isFraud = result?["is_fraud"] == true;

    final color = _riskColor(
      riskLevel,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // AMOUNT
        _field(
          amount,
          "amount",
        ),

        // HOUR
        _field(
          hour,
          "hour_of_day",
        ),

        // TRANSACTIONS
        _field(
          txns,
          "transactions_last_hour",
        ),

        // DEVICE
        _deviceField(),

        // ACCOUNT AGE
        _field(
          age,
          "account_age_days",
        ),

        // BUTTON
        GradientButton(
          label: "POST /check-transaction",
          onPressed: loading ? null : _run,
          loading: loading,
        ),

        // ERROR
        if (error != null)
          _errorBox(error!),

        // RESULT
        if (result != null)
          Container(
            margin: const EdgeInsets.only(
              top: 16,
            ),
            padding: const EdgeInsets.all(
              18,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(
                16,
              ),
              border: Border.all(
                color: color.withOpacity(0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // TOP ROW
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: Text(
                        riskLevel ?? "—",
                        style: TextStyle(
                          color: color,
                          fontWeight:
                              FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isFraud
                          ? Icons.gpp_bad
                          : Icons.verified_user,
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isFraud
                          ? "Flagged as fraud"
                          : "Looks legitimate",
                      style: TextStyle(
                        color: color,
                        fontWeight:
                            FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // PROBABILITY
                Text(
                  "Fraud probability: "
                  "${(probability * 100).toStringAsFixed(1)}%",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 6),

                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(6),
                  child:
                      LinearProgressIndicator(
                    value: probability
                        .clamp(0, 1)
                        .toDouble(),
                    minHeight: 8,
                    backgroundColor:
                        Colors.white
                            .withOpacity(0.08),
                    valueColor:
                        AlwaysStoppedAnimation(
                      color,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  height: 1,
                  color:
                      Colors.white.withOpacity(
                    0.08,
                  ),
                ),

                const SizedBox(height: 10),

                _kv(
                  "Transaction ID",
                  "#${result?["id"] ?? "—"}",
                ),

                _kv(
                  "Amount",
                  "Tk ${_fmtNum(result?["amount"] ?? amount.text)}",
                ),

                _kv(
                  "New device",
                  isNewDevice == 1
                      ? "Yes"
                      : "No",
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ============================================================
// HISTORY TAB
// ============================================================

class _HistoryTab extends StatefulWidget {
  final FraudService Function() getService;

  const _HistoryTab({
    required this.getService,
  });

  @override
  State<_HistoryTab> createState() =>
      _HistoryTabState();
}

class _HistoryTabState
    extends State<_HistoryTab> {
  List<dynamic>? result;
  String? error;
  bool loading = false;

  Future<void> _run() async {
    setState(() {
      loading = true;
      error = null;
      result = null;
    });

    try {
      final res =
          await widget.getService().getHistory();

      if (!mounted) return;

      setState(() {
        result = res;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst(
              "Exception: ",
              "",
            );
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        GradientButton(
          label: "GET /history",
          onPressed: loading ? null : _run,
          loading: loading,
        ),

        if (error != null)
          _errorBox(error!),

        if (result != null &&
            result!.isEmpty)
          const Padding(
            padding: EdgeInsets.only(
              top: 16,
            ),
            child: Text(
              "No transactions logged yet.",
              style: TextStyle(
                color: Colors.white54,
              ),
            ),
          ),

        if (result != null)
          ...result!.map(
            (raw) {
              final item =
                  raw as Map<String, dynamic>;

              final color = _riskColor(
                item["risk_level"] as String?,
              );

              final isFraud =
                  item["is_fraud"] == true;

              final probability =
                  (item["fraud_probability"]
                              as num?)
                          ?.toDouble() ??
                      0;

              return Container(
                margin:
                    const EdgeInsets.only(
                  top: 10,
                ),
                padding:
                    const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white
                      .withOpacity(0.04),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  border: Border.all(
                    color: color.withOpacity(
                      0.2,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration:
                              BoxDecoration(
                            color: color,
                            shape:
                                BoxShape.circle,
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          "#${item["id"]}",
                          style:
                              const TextStyle(
                            color: Colors.white,
                            fontWeight:
                                FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration:
                              BoxDecoration(
                            color: color
                                .withOpacity(
                              0.15,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                          child: Text(
                            item["risk_level"] ??
                                "—",
                            style: TextStyle(
                              color: color,
                              fontWeight:
                                  FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Container(
                      height: 1,
                      color: Colors.white
                          .withOpacity(0.06),
                    ),

                    const SizedBox(height: 8),

                    _kv(
                      "Amount",
                      "Tk ${_fmtNum(item["amount"])}",
                    ),

                    _kv(
                      "Hour of day",
                      _fmtNum(
                        item["hour_of_day"],
                      ),
                    ),

                    _kv(
                      "Txns last hour",
                      _fmtNum(
                        item[
                            "transactions_last_hour"],
                      ),
                    ),

                    _kv(
                      "New device",
                      item["is_new_device"] == 1
                          ? "Yes"
                          : "No",
                    ),

                    _kv(
                      "Account age (days)",
                      _fmtNum(
                        item[
                            "account_age_days"],
                      ),
                    ),

                    _kv(
                      "Fraud probability",
                      "${(probability * 100).toStringAsFixed(1)}%",
                    ),

                    _kv(
                      "Flagged fraud",
                      isFraud ? "Yes" : "No",
                      valueColor:
                          isFraud ? color : null,
                    ),

                    _kv(
                      "Logged at",
                      _fmtDate(
                        item["created_at"],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

// ============================================================
// STATS TAB
// ============================================================

class _StatsTab extends StatefulWidget {
  final FraudService Function() getService;

  const _StatsTab({
    required this.getService,
  });

  @override
  State<_StatsTab> createState() =>
      _StatsTabState();
}

class _StatsTabState
    extends State<_StatsTab> {
  Map<String, dynamic>? result;
  String? error;
  bool loading = false;

  Future<void> _run() async {
    setState(() {
      loading = true;
      error = null;
      result = null;
    });

    try {
      final res =
          await widget.getService().getStats();

      if (!mounted) return;

      setState(() {
        result = res;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst(
              "Exception: ",
              "",
            );
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalChecked =
        result?["total_checked"];

    final fraudDetected =
        result?["fraud_detected"];

    final fraudRate =
        (result?["fraud_rate"] as num?)
                ?.toDouble() ??
            0;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        GradientButton(
          label: "GET /stats",
          onPressed: loading ? null : _run,
          loading: loading,
        ),

        if (error != null)
          _errorBox(error!),

        if (result != null)
          Padding(
            padding:
                const EdgeInsets.only(top: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _statChip(
                  "Total checked",
                  _fmtNum(totalChecked),
                ),

                _statChip(
                  "Fraud detected",
                  _fmtNum(fraudDetected),
                  color:
                      const Color(0xFFFF5F6D),
                ),

                _statChip(
                  "Fraud rate",
                  "${(fraudRate * 100).toStringAsFixed(1)}%",
                  color:
                      const Color(0xFFFFC371),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

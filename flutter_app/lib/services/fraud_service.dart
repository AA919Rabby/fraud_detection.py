import 'dart:convert';
import 'package:http/http.dart' as http;

class FraudService {
  final String baseUrl;

  FraudService({required this.baseUrl, required this.apiKey});

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "x-api-key": fd_9k3m2Xp7qL8vR4tN,
      };

  Future<Map<String, dynamic>> health() async {
    final res = await http.get(Uri.parse("$baseUrl/health"));
    return _decode(res);
  }

  Future<Map<String, dynamic>> checkTransaction({
    required double amount,
    required double hourOfDay,
    required int transactionsLastHour,
    required int isNewDevice,
    required double accountAgeDays,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/check-transaction"),
      headers: _headers,
      body: jsonEncode({
        "amount": amount,
        "hour_of_day": hourOfDay,
        "transactions_last_hour": transactionsLastHour,
        "is_new_device": isNewDevice,
        "account_age_days": accountAgeDays,
      }),
    );
    return _decode(res);
  }

  Future<List<dynamic>> getHistory({int limit = 20}) async {
    final res = await http.get(
      Uri.parse("$baseUrl/history?limit=$limit"),
      headers: _headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    throw Exception("History failed: ${res.statusCode} ${res.body}");
  }

  Future<Map<String, dynamic>> getStats() async {
    final res = await http.get(Uri.parse("$baseUrl/stats"), headers: _headers);
    return _decode(res);
  }

  Future<Map<String, dynamic>> deleteTransaction(int id) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/transaction/$id"),
      headers: _headers,
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> clearAll() async {
    final res = await http.delete(
      Uri.parse("$baseUrl/transactions/clear-all"),
      headers: _headers,
    );
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception("Request failed: ${res.statusCode} ${res.body}");
  }
}
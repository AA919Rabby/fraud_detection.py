import 'dart:convert';
import 'package:http/http.dart' as http;

class FraudService {
  final String baseUrl;
  final String? token;

  FraudService({required this.baseUrl, this.token});

  Map<String, String> get _authHeaders => {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      };

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    return _decodeMap(res);
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {"username": email, "password": password},
    );
    final data = _decodeMap(res);
    return data["access_token"] as String;
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/forgot-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/reset-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "code": code,
        "new_password": newPassword,
      }),
    );
    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> health() async {
    final res = await http.get(Uri.parse("$baseUrl/health"));
    return _decodeMap(res);
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
      headers: _authHeaders,
      body: jsonEncode({
        "amount": amount,
        "hour_of_day": hourOfDay,
        "transactions_last_hour": transactionsLastHour,
        "is_new_device": isNewDevice,
        "account_age_days": accountAgeDays,
      }),
    );
    return _decodeMap(res);
  }

  Future<List<dynamic>> getHistory({int limit = 20}) async {
    final res = await http.get(
      Uri.parse("$baseUrl/history?limit=$limit"),
      headers: _authHeaders,
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    throw Exception(_extractError(res));
  }

  Future<Map<String, dynamic>> getStats() async {
    final res = await http.get(Uri.parse("$baseUrl/stats"), headers: _authHeaders);
    return _decodeMap(res);
  }

  Map<String, dynamic> _decodeMap(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_extractError(res));
  }

  String _extractError(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body["detail"] != null) {
        return body["detail"].toString();
      }
    } catch (_) {}
    return "Request failed (${res.statusCode})";
  }
}
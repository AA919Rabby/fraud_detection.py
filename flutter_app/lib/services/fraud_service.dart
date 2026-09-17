import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class FraudService {
  final String baseUrl;
  final String? token;

  FraudService({
    required this.baseUrl,
    this.token,
  });

  static const Duration requestTimeout =
      Duration(seconds: 30);

  Map<String, String> get _authHeaders => {
        "Content-Type": "application/json",

        if (token != null)
          "Authorization": "Bearer $token",
      };

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse("$baseUrl/register"),
            headers: {
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "email": email,
              "password": password,
            }),
          )
          .timeout(requestTimeout);

      return _decodeMap(res);
    } on TimeoutException {
      throw Exception(
        "Server took too long to respond.",
      );
    } catch (e) {
      throw Exception(
        "Could not connect to the server: $e",
      );
    }
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse("$baseUrl/login"),
            headers: {
              "Content-Type":
                  "application/x-www-form-urlencoded",
            },
            body: {
              "username": email,
              "password": password,
            },
          )
          .timeout(requestTimeout);

      final data = _decodeMap(res);

      final token = data["access_token"];

      if (token == null) {
        throw Exception(
          "Server did not return an access token.",
        );
      }

      return token.toString();
    } on TimeoutException {
      throw Exception(
        "Login timed out. The API may be starting up.",
      );
    }
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final res = await http
        .post(
          Uri.parse("$baseUrl/forgot-password"),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "email": email,
          }),
        )
        .timeout(requestTimeout);

    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final res = await http
        .post(
          Uri.parse("$baseUrl/reset-password"),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "email": email,
            "code": code,
            "new_password": newPassword,
          }),
        )
        .timeout(requestTimeout);

    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> health() async {
    final res = await http
        .get(
          Uri.parse("$baseUrl/health"),
        )
        .timeout(requestTimeout);

    return _decodeMap(res);
  }

  Future<Map<String, dynamic>> checkTransaction({
    required double amount,
    required double hourOfDay,
    required int transactionsLastHour,
    required int isNewDevice,
    required double accountAgeDays,
  }) async {
    if (isNewDevice != 0 &&
        isNewDevice != 1) {
      throw Exception(
        "New device must be 0 or 1.",
      );
    }

    final res = await http
        .post(
          Uri.parse(
            "$baseUrl/check-transaction",
          ),
          headers: _authHeaders,
          body: jsonEncode({
            "amount": amount,
            "hour_of_day": hourOfDay,
            "transactions_last_hour":
                transactionsLastHour,
            "is_new_device": isNewDevice,
            "account_age_days":
                accountAgeDays,
          }),
        )
        .timeout(requestTimeout);

    return _decodeMap(res);
  }

  Future<List<dynamic>> getHistory({
    int limit = 20,
  }) async {
    final res = await http
        .get(
          Uri.parse(
            "$baseUrl/history?limit=$limit",
          ),
          headers: _authHeaders,
        )
        .timeout(requestTimeout);

    if (res.statusCode == 200) {
      return jsonDecode(res.body)
          as List<dynamic>;
    }

    throw Exception(
      _extractError(res),
    );
  }

  Future<Map<String, dynamic>> getStats() async {
    final res = await http
        .get(
          Uri.parse("$baseUrl/stats"),
          headers: _authHeaders,
        )
        .timeout(requestTimeout);

    return _decodeMap(res);
  }

  Map<String, dynamic> _decodeMap(
    http.Response res,
  ) {
    if (res.statusCode >= 200 &&
        res.statusCode < 300) {
      return jsonDecode(res.body)
          as Map<String, dynamic>;
    }

    throw Exception(
      _extractError(res),
    );
  }

  String _extractError(
    http.Response res,
  ) {
    try {
      final body = jsonDecode(res.body);

      if (body is Map &&
          body["detail"] != null) {
        return body["detail"].toString();
      }
    } catch (_) {}

    return "Request failed (${res.statusCode})";
  }
}
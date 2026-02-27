import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = "https://deskreserve.onrender.com/api";

  /// Headers with token
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    return {
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  /// JSON Response handler
  static dynamic _handleResponse(http.Response res) {
    try {
      final body = jsonDecode(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return body;
      }

      final message =
          body['error'] ?? body['message'] ?? 'Something went wrong';

      throw Exception(message);
    } catch (e) {
      throw Exception("Unexpected server response");
    }
  }

  /*static dynamic _handleResponse(http.Response res) {
    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    final body = jsonDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    throw Exception(body['error'] ?? body['message'] ?? 'Something went wrong');
  }*/

  /// GET
  static Future<dynamic> get(String endpoint) async {
    final res = await http.get(
      Uri.parse("$baseUrl$endpoint"),
      headers: {"Content-Type": "application/json", ...await _headers()},
    );

    return _handleResponse(res);
  }

  /// POST
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl$endpoint"),
      headers: {"Content-Type": "application/json", ...await _headers()},
      body: jsonEncode(data),
    );

    return _handleResponse(res);
  }

  /// PATCH
  static Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final res = await http.patch(
      Uri.parse("$baseUrl$endpoint"),
      headers: {"Content-Type": "application/json", ...await _headers()},
      body: jsonEncode(data),
    );

    return _handleResponse(res);
  }

  /// DELETE
  static Future<dynamic> delete(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final res = await http.delete(
      Uri.parse("$baseUrl$endpoint"),
      headers: {"Content-Type": "application/json", ...await _headers()},
      body: jsonEncode(data),
    );

    return _handleResponse(res);
  }
}

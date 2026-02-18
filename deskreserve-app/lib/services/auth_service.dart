import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthService {
  /// Calls Node.js auth API
  /// Expected response:
  /// { "token": "...", "role": "ADMIN" | "EMPLOYEE" }
  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    try {
      final res = await ApiClient.post('/auth/login', {
        "email": email,
        "password": password,
      });

      if (res == null || res["token"] == null) {
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", res["token"]);

      return {"token": res["token"]};
    } catch (e) {
      return null;
    }
  }

  /// Optional helper for logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }
}

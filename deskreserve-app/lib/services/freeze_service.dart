import 'api_client.dart';

class FreezeService {
  static Future<Map<String, dynamic>?> getSubscriptionDetails({
    required String email,
  }) async {
    final res = await ApiClient.get('/subscription/details?email=$email');

    if (res == null) return null;

    return res;
  }

  /* =========================================================
     ❄ DIRECT FREEZE (ADMIN)
     POST /api/subscription/freeze
  ========================================================== */
  static Future<Map<String, dynamic>> freezeMembership({
    required String email,
    required int freezeDays,
  }) async {
    final res = await ApiClient.post('/subscription/freeze', {
      "email": email,
      "freeze_days": freezeDays,
    });

    if (res == null) {
      throw Exception("Failed to freeze membership");
    }

    return res;
  }

  static Future<bool> isUserFrozen({required String email}) async {
    final res = await ApiClient.get('/freeze/is-frozen?email=$email');

    if (res == null) return false;

    return res['isFrozen'] == true;
  }
}

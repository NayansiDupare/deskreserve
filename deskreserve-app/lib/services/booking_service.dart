import 'api_client.dart';

class BookingService {
  /* =========================================================
   🔴 LEGACY SLOT BOOKING (NOT USED IN SUBSCRIPTION FLOW)
   ========================================================== */
  static Future<void> bookSlot({
    String? email,
    required int seat,
    required String date,
    required String slot,
  }) async {
    final body = {"seat": seat, "date": date, "slot": slot, "email": ?email};

    await ApiClient.post('/seats/book-slot', body);
  }

  /* =========================================================
   ✅ 1️⃣ LIVE PRICE PREVIEW
   ========================================================== */
  static Future<Map<String, dynamic>> getQuotePreview({
    required int months,
    required List<Map<String, String>> slots,
    int discount = 0,
  }) async {
    final res = await ApiClient.post('/subscription/quote', {
      "months": months,
      "discount": discount,
      "slots": slots,
    });

    if (res == null || res is! Map) {
      throw Exception("Failed to fetch quote preview");
    }

    return {
      "baseAmount": res["baseAmount"],
      "discount": res["discount"],
      "discountAmount": res["discountAmount"],
      "finalAmount": res["finalAmount"],
    };
  }

  /* =========================================================
   ✅ 2️⃣ LOCK QUOTE
   ========================================================== */
  static Future<String> lockQuote({
    required int months,
    required List<Map<String, String>> slots,
    int discount = 0,
  }) async {
    final res = await ApiClient.post('/subscription/quote/lock', {
      "months": months,
      "discount": discount,
      "slots": slots,
    });

    if (res == null || res["quoteId"] == null) {
      throw Exception("Failed to lock quote");
    }

    return res["quoteId"];
  }

  /* =========================================================
   ✅ 3️⃣ FINAL SUBSCRIPTION CREATE (UPDATED)
   ========================================================== */
  static Future<void> createSubscription({
    required String quoteId,
    required String email,
    required int seat,

    // 🔹 ADDED
    required String slot,
    required String startDate,
    required String endDate,

    required Map<String, dynamic> payment,
    required Map<String, dynamic> student,
  }) async {
    final res = await ApiClient.post('/subscription/create', {
      "quoteId": quoteId,
      "email": email,
      "seat": seat,

      // 🔹 NEW FIELDS
      "slot": slot,
      "startDate": startDate,
      "endDate": endDate,

      "payment": payment,
      "student": student,
    });

    if (res == null) {
      throw Exception("Failed to create subscription");
    }
  }

  /* =========================================================
   📄 USER BOOKINGS
   ========================================================== */
  static Future<List<Map<String, dynamic>>> getMyBookings() async {
    final res = await ApiClient.get('/bookings/list');

    if (res == null || res is! List) return [];

    return res.map<Map<String, dynamic>>((b) {
      return {
        "seat": b['seat'],
        "startDate": b['startDate'],
        "endDate": b['endDate'],
        "slots": b['slots'],
        "status": b['status'],
      };
    }).toList();
  }

  /* =========================================================
   🔄 CHANGE SEAT
   ========================================================== */
  static Future<void> changeSeat({
    required String email,
    required int oldSeat,
    required int newSeat,
  }) async {
    final res = await ApiClient.post('/subscription/change-seat', {
      "email": email,
      "oldSeat": oldSeat,
      "newSeat": newSeat,
    });

    if (res == null || res['success'] != true) {
      throw Exception("Seat change failed");
    }
  }

  static Future<List<Map<String, dynamic>>> getAllSubscriptions() async {
    final res = await ApiClient.get('/subscription/all');

    if (res == null || res is! List) return [];

    return res.map<Map<String, dynamic>>((s) {
      return {
        "email": s['email'],
        "seat": s['seat'],
        "months": s['months'],
        "status": s['status'],
        "student_name": s['student_name'],
        "student_phone": s['student_phone'],
        "id_proof_type": s['id_proof_type'],
        "id_proof_url": s['id_proof_url'],
        "freeze_days_allowed": s['freeze_days_allowed'],
        "freeze_days_used": s['freeze_days_used'],
        "seat_change_allowed": s['seat_change_allowed'],
        "seat_change_used": s['seat_change_used'],
      };
    }).toList();
  }

  // ================= UPDATE =================
  static Future<void> updateSubscription({
    required String email,
    required Map<String, dynamic> updates,
  }) async {
    final res = await ApiClient.patch('/subscription/update', {
      "email": email,
      "updates": updates,
    });

    if (res == null || res['success'] != true) {
      throw Exception("Failed to update subscription");
    }
  }

  // ================= DELETE =================
  static Future<void> deleteSubscription({required String email}) async {
    final res = await ApiClient.delete('/subscription/delete', {
      "email": email,
    });

    if (res == null || res['success'] != true) {
      throw Exception("Failed to delete subscription");
    }
  }
}

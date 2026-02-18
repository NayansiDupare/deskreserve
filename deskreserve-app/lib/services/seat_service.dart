import 'api_client.dart';

class SeatService {
  static Future<List<Map<String, dynamic>>> getSeatStatus(String date) async {
    try {
      final res = await ApiClient.get('/seats/status?date=$date');

      if (res == null || res is! List) return [];

      return res.map<Map<String, dynamic>>((seat) {
        return {
          "seat": seat['seat'],
          "seatStatus": seat['seatStatus'], // ✅ FIXED
          "isAvailable": seat['isAvailable'],
          "slots": Map<String, String>.from(seat['slots']),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ✅ NEW METHOD — DO NOT TOUCH ABOVE CODE
  static Future<List<int>> getSeatAvailability({
    required String startDate,
    required String endDate,
    required String slot,
  }) async {
    try {
      final res = await ApiClient.get(
        '/seats/availability'
        '?startDate=$startDate'
        '&endDate=$endDate'
        '&slot=$slot',
      );

      if (res == null || res['availableSeats'] == null) {
        return [];
      }

      return List<int>.from(res['availableSeats']);
    } catch (e) {
      return [];
    }
  }
}

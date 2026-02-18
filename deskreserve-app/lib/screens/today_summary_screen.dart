import 'package:flutter/material.dart';
import '../services/seat_service.dart';

class TodaySummaryScreen extends StatefulWidget {
  const TodaySummaryScreen({super.key});

  @override
  State<TodaySummaryScreen> createState() => _TodaySummaryScreenState();
}

class _TodaySummaryScreenState extends State<TodaySummaryScreen> {
  static const int totalSeats = 75;

  bool loading = true;
  int bookedSeats = 0;
  int availableSeats = 0;

  List<Map<String, dynamic>> allSeats = [];

  String selectedView = ""; // "BOOKED" | "AVAILABLE"

  String get today => DateTime.now().toString().substring(0, 10);

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final seats = await SeatService.getSeatStatus(today);

      int bookedCount = 0;

      for (final seat in seats) {
        final slots = Map<String, String>.from(seat['slots']);
        if (slots.values.any((s) => s != 'FREE')) {
          bookedCount++;
        }
      }

      setState(() {
        allSeats = seats;
        bookedSeats = bookedCount;
        availableSeats = totalSeats - bookedCount;
        loading = false;
      });
    } catch (_) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text("Today's Summary"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// SUMMARY CARDS
                  Row(
                    children: [
                      _summaryBox(
                        title: "Total Seats",
                        value: totalSeats.toString(),
                        color: Colors.blue,
                        onTap: null,
                      ),
                      _summaryBox(
                        title: "Booked",
                        value: bookedSeats.toString(),
                        color: Colors.red,
                        onTap: () {
                          setState(() => selectedView = "BOOKED");
                        },
                      ),
                      _summaryBox(
                        title: "Available",
                        value: availableSeats.toString(),
                        color: Colors.green,
                        onTap: () {
                          setState(() => selectedView = "AVAILABLE");
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  /// DETAILS LIST
                  Expanded(child: _buildDetails()),
                ],
              ),
            ),
    );
  }

  /// ================= DETAILS =================

  Widget _buildDetails() {
    if (selectedView.isEmpty) {
      return Center(
        child: Text(
          "Tap on Booked or Available to see details",
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    final List<Widget> items = [];

    for (final seat in allSeats) {
      final seatNo = seat['seat'];
      final slots = Map<String, String>.from(seat['slots']);

      final filteredSlots = slots.entries.where((e) {
        return selectedView == "BOOKED" ? e.value != 'FREE' : e.value == 'FREE';
      }).toList();

      if (filteredSlots.isEmpty) continue;

      items.add(
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Seat $seatNo",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: filteredSlots.map((slot) {
                    return Chip(
                      label: Text(slot.key),
                      backgroundColor: selectedView == "BOOKED"
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return items.isEmpty
        ? const Center(child: Text("No data found"))
        : ListView(children: items);
  }

  /// ================= SUMMARY BOX =================

  Widget _summaryBox({
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}

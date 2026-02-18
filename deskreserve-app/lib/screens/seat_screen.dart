import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/seat_service.dart';
import '../widgets/seat_grid.dart';
import '../widgets/app_drawer.dart';
import '../widgets/slot_selection_dialog.dart';

class SeatScreen extends StatefulWidget {
  const SeatScreen({super.key});

  @override
  State<SeatScreen> createState() => _SeatScreenState();
}

class _SeatScreenState extends State<SeatScreen> {
  List<Map<String, dynamic>> seats = [];
  bool loading = true;
  int? selectedSeat;

  Timer? _refreshTimer;

  String get today => DateTime.now().toString().substring(0, 10);

  @override
  void initState() {
    super.initState();
    _loadSeats();

    // 🔥 Auto refresh every 10 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadSeats(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSeats() async {
    try {
      final seatData = await SeatService.getSeatStatus(today);

      setState(() {
        seats = seatData;
        loading = false;
      });
    } catch (_) {
      setState(() {
        seats = [];
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(role: 'EMPLOYEE'),
      appBar: AppBar(
        title: Text(
          "Seat Status",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF4A6CF7),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : seats.isEmpty
          ? const Center(
              child: Text(
                "No seats available",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : SeatGrid(
              seats: seats,
              selectedSeat: selectedSeat,
              onSeatTap: (seat) async {
                // 🔥 Only show slot info
                setState(() {
                  selectedSeat = seat['seat'];
                });

                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (_) => SlotSelectionDialog(
                    seatNumber: seat['seat'],
                    slots: Map<String, String>.from(seat['slots']),
                  ),
                );
              },
            ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/seat_service.dart';
import '../widgets/seat_grid.dart';
import 'payment_screen.dart';
import 'confirm_change_seat_screen.dart';

enum SeatScreenMode { viewOnly, createSubscription, changeSeat }

class SeatSelectionScreen extends StatefulWidget {
  final SeatScreenMode mode;
  final String startDate;
  final String endDate;

  final String quoteId;
  final int finalAmount;

  // 🔥 For Change Seat Flow
  final String? email;
  final int? oldSeat;

  // 🔥 Seat change limits
  final int? seatChangeAllowed;
  final int? seatChangeUsed;

  const SeatSelectionScreen({
    super.key,
    required this.mode,
    required this.startDate,
    required this.endDate,
    required this.quoteId,
    required this.finalAmount,
    this.email,
    this.oldSeat,
    this.seatChangeAllowed,
    this.seatChangeUsed,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  List<Map<String, dynamic>> seats = [];
  int? selectedSeat;
  bool isLoading = true;

  String selectedSlot = "08:00-14:00";

  final List<String> slots = ["08:00-14:00", "14:00-20:00", "20:00-24:00"];

  @override
  void initState() {
    super.initState();
    fetchSeatAvailability();
  }

  Future<void> fetchSeatAvailability() async {
    setState(() => isLoading = true);

    try {
      final availableSeats = await SeatService.getSeatAvailability(
        startDate: widget.startDate,
        endDate: widget.endDate,
        slot: selectedSlot,
      );

      List<Map<String, dynamic>> generatedSeats = List.generate(75, (index) {
        final seatNumber = index + 1;
        final isAvailable = availableSeats.contains(seatNumber);

        return {
          "seat": seatNumber,
          "seatStatus": isAvailable ? "AVAILABLE" : "FULL",
        };
      });

      setState(() {
        seats = generatedSeats;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  bool get isViewOnly => widget.mode == SeatScreenMode.viewOnly;

  bool get isSeatChangeLimitReached {
    if (widget.mode != SeatScreenMode.changeSeat) return false;

    if (widget.seatChangeAllowed == null || widget.seatChangeUsed == null) {
      return false;
    }

    return widget.seatChangeUsed! >= widget.seatChangeAllowed!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: const Color(0xFF4A6CF7),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                /// 🔹 Slot Dropdown
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedSlot,
                    decoration: const InputDecoration(
                      labelText: "Select Slot",
                      border: OutlineInputBorder(),
                    ),
                    items: slots
                        .map(
                          (slot) =>
                              DropdownMenuItem(value: slot, child: Text(slot)),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSlot = value!;
                        selectedSeat = null;
                      });
                      fetchSeatAvailability();
                    },
                  ),
                ),

                /// 🔹 Seat Change Info (Only in Change Mode)
                if (widget.mode == SeatScreenMode.changeSeat &&
                    widget.seatChangeAllowed != null &&
                    widget.seatChangeUsed != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Allowed: ${widget.seatChangeAllowed}"),
                          Text("Used: ${widget.seatChangeUsed}"),
                          Text(
                            "Remaining: ${widget.seatChangeAllowed! - widget.seatChangeUsed!}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                /// 🔹 Seat Grid
                Expanded(
                  child: SeatGrid(
                    seats: seats,
                    selectedSeat: selectedSeat,
                    onSeatTap: isViewOnly
                        ? null
                        : (seat) {
                            if (seat['seatStatus'] == 'FULL') return;

                            setState(() {
                              selectedSeat = seat['seat'];
                            });
                          },
                  ),
                ),

                /// 🔹 Confirm Button
                if (!isViewOnly) buildConfirmButton(),
              ],
            ),
    );
  }

  String _getTitle() {
    switch (widget.mode) {
      case SeatScreenMode.viewOnly:
        return "Seat Availability";
      case SeatScreenMode.createSubscription:
        return "Select Seat";
      case SeatScreenMode.changeSeat:
        return "Change Seat";
    }
  }

  Widget buildConfirmButton() {
    final isDisabled = selectedSeat == null || isSeatChangeLimitReached;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: isDisabled
            ? null
            : () {
                /// 🔵 CREATE SUBSCRIPTION FLOW
                if (widget.mode == SeatScreenMode.createSubscription) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        quoteId: widget.quoteId,
                        seatNumber: selectedSeat!,
                        finalAmount: widget.finalAmount,
                        slot: selectedSlot,
                        startDate: widget.startDate,
                        endDate: widget.endDate,
                      ),
                    ),
                  );
                }
                /// 🟢 CHANGE SEAT FLOW
                else if (widget.mode == SeatScreenMode.changeSeat) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConfirmChangeSeatScreen(
                        email: widget.email!,
                        oldSeat: widget.oldSeat!,
                        newSeat: selectedSeat!,
                      ),
                    ),
                  );
                }
              },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: const Color(0xFF4A6CF7),
        ),
        child: const Text("Confirm Seat"),
      ),
    );
  }
}

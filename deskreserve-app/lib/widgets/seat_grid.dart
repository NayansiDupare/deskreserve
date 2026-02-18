import 'package:flutter/material.dart';

class SeatGrid extends StatelessWidget {
  final List<Map<String, dynamic>> seats;
  final void Function(Map<String, dynamic> seat)? onSeatTap;
  final int? selectedSeat;

  const SeatGrid({
    super.key,
    required this.seats,
    this.onSeatTap,
    this.selectedSeat,
  });

  Color _seatColor(String seatStatus, bool isSelected, bool isMine) {
    if (isSelected) return Colors.blue.shade700; // Selected seat
    if (isMine) return Colors.blue.shade400; // My booked seat

    switch (seatStatus) {
      case 'FULL':
        return Colors.red.shade500; // 🔴 Fully booked
      case 'PARTIAL':
        return Colors.orange.shade400; // 🟡 Partial
      case 'AVAILABLE':
        return Colors.green.shade500; // 🟢 Fully available
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (seats.isEmpty) {
      return const Center(
        child: Text("No seats available", style: TextStyle(color: Colors.grey)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: seats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final seat = seats[index];

        final int seatNumber = seat['seat'];
        final String seatStatus = (seat['seatStatus'] ?? 'AVAILABLE')
            .toString();

        final bool isMine = seat['isMine'] ?? false;
        final bool isSelected = selectedSeat == seatNumber;

        final bool isFull = seatStatus == 'FULL';

        return GestureDetector(
          onTap: isFull ? null : () => onSeatTap?.call(seat),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: isSelected ? 1.1 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),

              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _seatColor(seatStatus, isSelected, isMine),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  if (isSelected)
                    const BoxShadow(color: Colors.black26, blurRadius: 6),
                ],
              ),
              child: Text(
                "S$seatNumber",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'interactive_slot_chip.dart';

class SeatSlotStatus extends StatelessWidget {
  final int seatNumber;
  final Map<String, String> slots;
  // slot status values expected:
  // FREE | BOOKED | USER_BOOKED

  const SeatSlotStatus({
    super.key,
    required this.seatNumber,
    required this.slots,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Seat $seatNumber",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: slots.entries.map((entry) {
                return InteractiveSlotChip(
                  slotName: entry.key,
                  status: entry.value, // FREE | BOOKED | USER_BOOKED
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

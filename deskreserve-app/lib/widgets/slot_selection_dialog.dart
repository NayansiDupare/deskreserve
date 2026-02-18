import 'package:flutter/material.dart';
import 'selectable_slot_chip.dart';

class SlotSelectionDialog extends StatefulWidget {
  final int seatNumber;
  final Map<String, String> slots;

  const SlotSelectionDialog({
    super.key,
    required this.seatNumber,
    required this.slots,
  });

  @override
  State<SlotSelectionDialog> createState() => _SlotSelectionDialogState();
}

class _SlotSelectionDialogState extends State<SlotSelectionDialog> {
  final Set<String> selectedSlots = {};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Seat ${widget.seatNumber}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.slots.entries.map((entry) {
              final String slotName = entry.key;
              final String status = entry.value;

              final bool isBooked = status == "BOOKED";
              final bool isSelected = selectedSlots.contains(slotName);

              return SelectableSlotChip(
                slotName: slotName,
                status: status,
                selected: isSelected,
                onTap: isBooked
                    ? null // 🔴 Disable if booked
                    : () {
                        setState(() {
                          if (isSelected) {
                            selectedSlots.remove(slotName);
                          } else {
                            selectedSlots.add(slotName);
                          }
                        });
                      },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedSlots.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context, selectedSlots.toList());
                    },
              child: const Text("Continue"),
            ),
          ),
        ],
      ),
    );
  }
}

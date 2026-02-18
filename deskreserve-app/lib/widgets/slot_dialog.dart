import 'package:flutter/material.dart';

class SlotDialog extends StatefulWidget {
  final int seatNumber;
  final List<String> slots;

  const SlotDialog({super.key, required this.seatNumber, required this.slots});

  @override
  State<SlotDialog> createState() => _SlotDialogState();
}

class _SlotDialogState extends State<SlotDialog> {
  String? selectedSlot;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Seat ${widget.seatNumber}"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.slots.map((slot) {
          return RadioListTile<String>(
            title: Text(slot),
            value: slot,
            groupValue: selectedSlot,
            onChanged: (val) {
              setState(() {
                selectedSlot = val;
              });
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: selectedSlot == null
              ? null
              : () {
                  Navigator.pop(context, selectedSlot);
                },
          child: const Text("Confirm"),
        ),
      ],
    );
  }
}

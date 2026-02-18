import 'package:flutter/material.dart';

class SelectableSlotChip extends StatelessWidget {
  final String slotName;
  final String status; // AVAILABLE | BOOKED
  final bool selected;
  final VoidCallback? onTap;

  const SelectableSlotChip({
    super.key,
    required this.slotName,
    required this.status,
    required this.selected,
    this.onTap,
  });

  Color _backgroundColor() {
    if (status == 'BOOKED') {
      return Colors.red.shade400; // 🔴 booked
    }

    if (selected) {
      return Colors.blue.shade600; // 🔵 selected
    }

    return Colors.green.shade500; // 🟢 available
  }

  @override
  Widget build(BuildContext context) {
    final bool isBooked = status == 'BOOKED';

    return GestureDetector(
      onTap: isBooked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _backgroundColor(),
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected && !isBooked
              ? [const BoxShadow(color: Colors.black26, blurRadius: 4)]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              slotName.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                decoration: isBooked ? TextDecoration.lineThrough : null,
              ),
            ),
            if (isBooked) ...[
              const SizedBox(width: 6),
              const Icon(Icons.lock, size: 14, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class InteractiveSlotChip extends StatelessWidget {
  final String slotName;
  final String status; // FREE | BOOKED | USER_BOOKED

  const InteractiveSlotChip({
    super.key,
    required this.slotName,
    required this.status,
  });

  Color _getColor() {
    switch (status) {
      case 'FREE':
        return Colors.green.shade500;
      case 'BOOKED':
        return Colors.red.shade400;
      case 'USER_BOOKED':
        return Colors.blue.shade500;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: _getColor(),
      label: Text(
        slotName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

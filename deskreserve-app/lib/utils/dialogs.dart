import 'package:flutter/material.dart';

Future<bool> showCancelConfirmDialog(
  BuildContext context,
  int seatNumber,
  String slot,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Cancel Booking"),
            content: Text(
              "Do you want to cancel booking for:\n\n"
              "Seat $seatNumber\nSlot $slot ?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Yes, Cancel"),
              ),
            ],
          );
        },
      ) ??
      false;
}

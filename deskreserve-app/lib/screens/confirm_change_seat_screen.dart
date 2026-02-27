import 'package:flutter/material.dart';
import '../services/booking_service.dart';

class ConfirmChangeSeatScreen extends StatelessWidget {
  final String email;
  final int oldSeat;
  final int newSeat;

  const ConfirmChangeSeatScreen({
    super.key,
    required this.email,
    required this.oldSeat,
    required this.newSeat,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Seat"),
        backgroundColor: const Color(0xFF4A6CF7),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            const Text(
              "Student",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 6),

            Text(email),

            const SizedBox(height: 20),

            Text("Current Seat: S$oldSeat"),

            const SizedBox(height: 10),

            Text(
              "New Seat: S$newSeat",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6CF7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  await BookingService.changeSeat(
                    email: email,
                    oldSeat: oldSeat,
                    newSeat: newSeat,
                  );

                  Navigator.pop(context); // Confirm screen
                  Navigator.pop(context); // Seat screen
                  Navigator.pop(context); // ChangeSeat screen
                },
                child: const Text("Confirm Change"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

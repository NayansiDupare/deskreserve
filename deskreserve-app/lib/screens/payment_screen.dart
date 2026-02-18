import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'student_details_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String quoteId;
  final int seatNumber;
  final int finalAmount;

  // 🔹 ADDED
  final String slot;
  final String startDate;
  final String endDate;

  const PaymentScreen({
    super.key,
    required this.quoteId,
    required this.seatNumber,
    required this.finalAmount,
    required this.slot,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool loading = false;
  String paymentMode = "UPI";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Payment"),
        backgroundColor: const Color(0xFF4A6CF7),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Seat Selected",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Seat Number"),
                      Text(
                        "S${widget.seatNumber}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 🔹 ADDED SLOT DISPLAY
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Slot"),
                      Text(
                        widget.slot,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 🔹 ADDED DATE RANGE DISPLAY
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Duration"),
                      Text(
                        "${widget.startDate} → ${widget.endDate}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              "Payment Summary",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Amount : ₹${widget.finalAmount}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  const Text("Select Payment Mode"),
                  const SizedBox(height: 6),

                  RadioListTile(
                    value: "UPI",
                    groupValue: paymentMode,
                    onChanged: (v) => setState(() => paymentMode = v!),
                    title: const Text("UPI"),
                  ),
                  RadioListTile(
                    value: "CASH",
                    groupValue: paymentMode,
                    onChanged: (v) => setState(() => paymentMode = v!),
                    title: const Text("Cash"),
                  ),
                  RadioListTile(
                    value: "CARD",
                    groupValue: paymentMode,
                    onChanged: (v) => setState(() => paymentMode = v!),
                    title: const Text("Card"),
                  ),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6CF7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: loading
                    ? null
                    : () {
                        setState(() => loading = true);

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentDetailsScreen(
                              quoteId: widget.quoteId,
                              seatNumber: widget.seatNumber,
                              finalAmount: widget.finalAmount,
                              paymentMode: paymentMode,

                              // 🔹 FORWARD ADDED VALUES
                              slot: widget.slot,
                              startDate: widget.startDate,
                              endDate: widget.endDate,
                            ),
                          ),
                        );
                      },
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Proceed to Student Details",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

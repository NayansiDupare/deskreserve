import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/booking_service.dart';
import '../services/upload_service.dart';
import 'my_bookings_screen.dart';

class StudentDetailsScreen extends StatefulWidget {
  final String quoteId;
  final int seatNumber;
  final int finalAmount;
  final String paymentMode;

  // 🔹 ADDED
  final String slot;
  final String startDate;
  final String endDate;

  const StudentDetailsScreen({
    super.key,
    required this.quoteId,
    required this.seatNumber,
    required this.finalAmount,
    required this.paymentMode,
    required this.slot,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();

  File? idProofFile;
  bool loading = false;

  final ImagePicker _picker = ImagePicker();

  /* ================= PICK IMAGE ================= */
  Future<void> _pickIdProof() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;

    setState(() {
      idProofFile = File(picked.path);
    });
  }

  /* ================= SUBMIT ================= */
  Future<void> _submit() async {
    if (nameCtrl.text.isEmpty ||
        phoneCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    if (idProofFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please upload ID proof")));
      return;
    }

    try {
      setState(() => loading = true);

      // 🔥 1. Upload ID Proof
      final String uploadedIdUrl = await UploadService.uploadIdProof(
        idProofFile!,
      );

      // 🔥 2. Payment Map
      final Map<String, dynamic> paymentData = {
        "paidAmount": widget.finalAmount,
        "mode": widget.paymentMode,
      };

      // 🔥 3. Student Map
      final Map<String, dynamic> studentData = {
        "name": nameCtrl.text.trim(),
        "phone": phoneCtrl.text.trim(),
        "idProofType": "Aadhar",
        "idProofUrl": uploadedIdUrl,
      };

      // 🔥 4. Create Subscription (UPDATED PAYLOAD)
      await BookingService.createSubscription(
        quoteId: widget.quoteId,
        email: emailCtrl.text.trim(),
        seat: widget.seatNumber,

        // 🔹 ADDED
        slot: widget.slot,
        startDate: widget.startDate,
        endDate: widget.endDate,

        payment: paymentData,
        student: studentData,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
        (_) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => loading = false);
    }
  }

  /* ================= UI ================= */
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
        title: const Text("Student Details"),
        backgroundColor: const Color(0xFF4A6CF7),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Phone Number"),
            ),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: _pickIdProof,
              icon: const Icon(Icons.upload),
              label: Text(
                idProofFile == null
                    ? "Upload ID Proof"
                    : idProofFile!.path.split('/').last,
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : _submit,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Finish Booking"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

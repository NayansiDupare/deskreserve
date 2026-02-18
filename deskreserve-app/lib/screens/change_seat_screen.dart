import 'package:flutter/material.dart';
import '../services/freeze_service.dart';
import 'seat_selection_screen.dart';

class ChangeSeatScreen extends StatefulWidget {
  final String email;
  final int currentSeat;

  const ChangeSeatScreen({
    super.key,
    required this.email,
    required this.currentSeat,
  });

  @override
  State<ChangeSeatScreen> createState() => _ChangeSeatScreenState();
}

class _ChangeSeatScreenState extends State<ChangeSeatScreen> {
  Map<String, dynamic>? subscription;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    try {
      final sub = await FreezeService.getSubscriptionDetails(
        email: widget.email,
      );

      setState(() {
        subscription = sub;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _handleSeatChange() {
    if (subscription == null) return;

    final allowed = subscription!["seat_change_allowed"] ?? 0;
    final used = subscription!["seat_change_used"] ?? 0;
    final status = subscription!["status"] ?? "";

    if (used >= allowed) {
      _showMessage("Seat change limit exceeded");
      return;
    }

    if (status == "FROZEN") {
      _showMessage("Cannot change seat. Subscription is frozen.");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeatSelectionScreen(
          mode: SeatScreenMode.changeSeat,
          startDate: DateTime.now().toString().substring(0, 10),
          endDate: DateTime.now().toString().substring(0, 10),
          quoteId: "",
          finalAmount: 0,
          email: widget.email,
          oldSeat: widget.currentSeat,
          seatChangeAllowed: allowed,
          seatChangeUsed: used,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final months = subscription?["months"] ?? 0;
    final allowed = subscription?["seat_change_allowed"] ?? 0;
    final used = subscription?["seat_change_used"] ?? 0;
    final status = subscription?["status"] ?? "";

    final remaining = allowed - used;

    /// 🔥 FINAL DISABLE CONDITION
    final bool isDisabled =
        months == 1 || // 1 month plan
        remaining <= 0 || // limit exceeded
        status == "FROZEN"; // frozen subscription

    String? disabledReason;

    if (months == 1) {
      disabledReason = "Seat change not available for 1 month plan";
    } else if (remaining <= 0) {
      disabledReason = "Seat change limit exceeded";
    } else if (status == "FROZEN") {
      disabledReason = "Subscription is currently frozen";
    }

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
            Text(widget.email),

            const SizedBox(height: 20),
            Text("Current Seat: S${widget.currentSeat}"),

            const SizedBox(height: 30),

            /// 🔥 Seat Change Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Seat Changes Allowed: $allowed"),
                  Text("Seat Changes Used: $used"),
                  Text(
                    "Remaining: $remaining",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6CF7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: isDisabled ? null : _handleSeatChange,
                child: const Text("Select New Seat"),
              ),
            ),

            if (isDisabled && disabledReason != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  disabledReason,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

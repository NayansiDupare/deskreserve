import 'package:flutter/material.dart';
import '../services/freeze_service.dart';

class FreezeMembershipScreen extends StatefulWidget {
  final String email;

  const FreezeMembershipScreen({super.key, required this.email});

  @override
  State<FreezeMembershipScreen> createState() => _FreezeMembershipScreenState();
}

class _FreezeMembershipScreenState extends State<FreezeMembershipScreen> {
  bool loading = true;
  Map<String, dynamic>? subscription;

  final TextEditingController freezeDaysController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    try {
      final res = await FreezeService.getSubscriptionDetails(
        email: widget.email,
      );

      setState(() {
        subscription = res;
        loading = false;
      });
    } catch (_) {
      setState(() => loading = false);
    }
  }

  Future<void> _freezeNow() async {
    final freezeDays = int.tryParse(freezeDaysController.text.trim());

    if (freezeDays == null || freezeDays <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter valid freeze days")));
      return;
    }

    try {
      await FreezeService.freezeMembership(
        email: widget.email,
        freezeDays: freezeDays,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Freeze applied successfully")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (subscription == null) {
      return const Scaffold(
        body: Center(child: Text("Subscription not found")),
      );
    }

    final allowed =
        int.tryParse(subscription!["freeze_days_allowed"]?.toString() ?? "0") ??
        0;

    final used =
        int.tryParse(subscription!["freeze_days_used"]?.toString() ?? "0") ?? 0;

    final remaining = allowed - used;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Freeze Membership"),
        backgroundColor: const Color(0xFF4A6CF7),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Seat: ${subscription!["seat"]}"),
            const SizedBox(height: 8),
            Text("Start Date: ${subscription!["start_date"]}"),
            Text("End Date: ${subscription!["end_date"]}"),
            const SizedBox(height: 20),
            Text("Freeze Allowed: $allowed"),
            Text("Freeze Used: $used"),
            Text(
              "Remaining: $remaining",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: freezeDaysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter Freeze Days",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6CF7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: remaining <= 0 ? null : _freezeNow,
                child: const Text("Freeze Now"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

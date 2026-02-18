import 'package:flutter/material.dart';
import '../services/booking_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  bool loading = true;

  int totalActive = 0;
  int totalFrozen = 0;
  int totalSeats = 75;
  int occupiedSeats = 0;

  double freezeUsagePercent = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final data = await BookingService.getAllSubscriptions();

      int active = 0;
      int frozen = 0;
      int occupied = data.length;

      int totalFreezeAllowed = 0;
      int totalFreezeUsed = 0;

      for (var s in data) {
        if (s['status'] == "ACTIVE") active++;
        if (s['status'] == "FROZEN") frozen++;

        totalFreezeAllowed +=
            int.tryParse(s['freeze_days_allowed']?.toString() ?? "0") ?? 0;

        totalFreezeUsed +=
            int.tryParse(s['freeze_days_used']?.toString() ?? "0") ?? 0;
      }

      double freezePercent = totalFreezeAllowed == 0
          ? 0
          : totalFreezeUsed / totalFreezeAllowed;

      setState(() {
        totalActive = active;
        totalFrozen = frozen;
        occupiedSeats = occupied;
        freezeUsagePercent = freezePercent;
        loading = false;
      });
    } catch (_) {
      setState(() => loading = false);
    }
  }

  double get occupancyPercent =>
      totalSeats == 0 ? 0 : occupiedSeats / totalSeats;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text("Analytics Dashboard"),
          backgroundColor: const Color(0xFF4A6CF7),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadAnalytics,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _headerCard(),
                    const SizedBox(height: 30),

                    /// KPI ROW
                    Row(
                      children: [
                        Expanded(
                          child: _premiumCard(
                            title: "Active",
                            value: totalActive.toString(),
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _premiumCard(
                            title: "Frozen",
                            value: totalFrozen.toString(),
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _premiumCard(
                      title: "Occupied Seats",
                      value: "$occupiedSeats / $totalSeats",
                      color: Colors.blue,
                    ),

                    const SizedBox(height: 30),

                    _progressSection(
                      title: "Seat Occupancy",
                      percent: occupancyPercent,
                      color: Colors.blue,
                    ),

                    const SizedBox(height: 30),

                    _progressSection(
                      title: "Freeze Usage",
                      percent: freezeUsagePercent,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /* ================= HEADER ================= */

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A6CF7), Color(0xFF6A8BFF)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "DeskReserve Analytics",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Monitor subscriptions & performance",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /* ================= KPI CARD ================= */

  Widget _premiumCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /* ================= PROGRESS ================= */

  Widget _progressSection({
    required String title,
    required double percent,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: percent,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            color: color,
          ),
          const SizedBox(height: 8),
          Text("${(percent * 100).toStringAsFixed(1)}%"),
        ],
      ),
    );
  }
}

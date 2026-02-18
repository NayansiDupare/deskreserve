import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import 'seat_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  bool loading = true;

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filtered = [];

  String searchQuery = "";
  String selectedFilter = "ALL";

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  /* ================= LOAD ================= */

  Future<void> _loadStudents() async {
    setState(() => loading = true);

    try {
      final data = await BookingService.getAllSubscriptions();

      setState(() {
        students = data;
        loading = false;
      });

      _applyFilter();
    } catch (_) {
      setState(() => loading = false);
    }
  }

  /* ================= FILTER ================= */

  void _applyFilter() {
    setState(() {
      filtered = students.where((s) {
        final email = (s['email'] ?? "").toString().toLowerCase();
        final status = _getComputedStatus(s);

        final matchesSearch = email.contains(searchQuery.toLowerCase());

        final matchesFilter =
            selectedFilter == "ALL" || status == selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  /* ================= STATUS LOGIC ================= */

  String _getComputedStatus(Map<String, dynamic> s) {
    final endDateStr = s['endDate'];
    if (endDateStr == null) return s['status'] ?? "UNKNOWN";

    final endDate = DateTime.tryParse(endDateStr);
    if (endDate == null) return s['status'] ?? "UNKNOWN";

    if (DateTime.now().isAfter(endDate)) {
      return "EXPIRED";
    }

    return s['status'] ?? "UNKNOWN";
  }

  /* ================= NAVIGATION ================= */

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SeatScreen()),
      (route) => false,
    );
  }

  Color _getStatusColor(String status) {
    if (status == "ACTIVE") return Colors.green;
    if (status == "FROZEN") return Colors.orange;
    if (status == "EXPIRED") return Colors.red;
    return Colors.grey;
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goHome();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goHome,
          ),
          title: const Text("My Bookings"),
          backgroundColor: const Color(0xFF4A6CF7),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadStudents,
                child: Column(
                  children: [
                    /// SEARCH + FILTER
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: "Search by email",
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                searchQuery = value;
                                _applyFilter();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          DropdownButton<String>(
                            value: selectedFilter,
                            items: const [
                              DropdownMenuItem(
                                value: "ALL",
                                child: Text("All"),
                              ),
                              DropdownMenuItem(
                                value: "ACTIVE",
                                child: Text("Active"),
                              ),
                              DropdownMenuItem(
                                value: "FROZEN",
                                child: Text("Frozen"),
                              ),
                              DropdownMenuItem(
                                value: "EXPIRED",
                                child: Text("Expired"),
                              ),
                            ],
                            onChanged: (value) {
                              selectedFilter = value!;
                              _applyFilter();
                            },
                          ),
                        ],
                      ),
                    ),

                    /// LIST
                    Expanded(
                      child: filtered.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 200),
                                Center(
                                  child: Text(
                                    "No bookings found",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (_, index) {
                                final s = filtered[index];

                                final freezeAllowed =
                                    s["freeze_days_allowed"] ?? 0;
                                final freezeUsed = s["freeze_days_used"] ?? 0;

                                final seatAllowed =
                                    s["seat_change_allowed"] ?? 0;
                                final seatUsed = s["seat_change_used"] ?? 0;

                                final freezeRemaining =
                                    freezeAllowed - freezeUsed;

                                final seatRemaining = seatAllowed - seatUsed;

                                final status = _getComputedStatus(s);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        /// HEADER
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Seat ${s['seat']}",
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(
                                                  status,
                                                ).withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                status,
                                                style: TextStyle(
                                                  color: _getStatusColor(
                                                    status,
                                                  ),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 10),

                                        Text("Email: ${s['email']}"),
                                        Text("Plan: ${s['months']} Months"),

                                        const SizedBox(height: 10),

                                        Text(
                                          "Freeze Remaining: $freezeRemaining days",
                                        ),
                                        Text(
                                          "Seat Change Remaining: $seatRemaining",
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import 'change_seat_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
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

  Future<void> _loadStudents() async {
    setState(() => loading = true);

    try {
      final data = await BookingService.getAllSubscriptions();

      setState(() {
        students = data;
        filtered = data;
        loading = false;
      });
    } catch (_) {
      setState(() {
        students = [];
        filtered = [];
        loading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      filtered = students.where((s) {
        final email = (s['email'] ?? "").toString().toLowerCase();
        final status = (s['status'] ?? "").toString().toUpperCase();

        final matchesSearch = email.contains(searchQuery.toLowerCase());

        final matchesFilter =
            selectedFilter == "ALL" || status == selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Color _statusColor(String status) {
    if (status == "ACTIVE") return Colors.green;
    if (status == "FROZEN") return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Students"),
        backgroundColor: const Color(0xFF4A6CF7),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                /// 🔍 SEARCH + FILTER
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
                          DropdownMenuItem(value: "ALL", child: Text("All")),
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

                /// 📋 LIST
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            "No students found",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadStudents,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final s = filtered[index];

                              final freezeAllowed =
                                  s["freeze_days_allowed"] ?? 0;
                              final freezeUsed = s["freeze_days_used"] ?? 0;

                              final seatAllowed = s["seat_change_allowed"] ?? 0;
                              final seatUsed = s["seat_change_used"] ?? 0;

                              final freezeRemaining =
                                  freezeAllowed - freezeUsed;

                              final seatRemaining = seatAllowed - seatUsed;

                              final status = s["status"] ?? "UNKNOWN";

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
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
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _statusColor(
                                                status,
                                              ).withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                color: _statusColor(status),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 8),

                                      Text("Email: ${s['email']}"),
                                      Text("Plan: ${s['months']} Months"),

                                      const SizedBox(height: 8),

                                      Text(
                                        "Freeze Remaining: $freezeRemaining days",
                                      ),
                                      Text(
                                        "Seat Change Remaining: $seatRemaining",
                                      ),

                                      const SizedBox(height: 12),

                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ChangeSeatScreen(
                                                      email: s['email'],
                                                      currentSeat: s['seat'],
                                                    ),
                                              ),
                                            );

                                            if (result == true) {
                                              _loadStudents();
                                            }
                                          },
                                          child: const Text("Change Seat"),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

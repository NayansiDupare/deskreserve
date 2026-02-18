import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import '../services/freeze_service.dart';
import 'freeze_membership_screen.dart';

class FreezeStudentSelectionScreen extends StatefulWidget {
  const FreezeStudentSelectionScreen({super.key});

  @override
  State<FreezeStudentSelectionScreen> createState() =>
      _FreezeStudentSelectionScreenState();
}

class _FreezeStudentSelectionScreenState
    extends State<FreezeStudentSelectionScreen> {
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
    try {
      final data = await BookingService.getAllSubscriptions();

      setState(() {
        students = data;
        filtered = data;
        loading = false;
      });

      await _applyFilter();
    } catch (_) {
      setState(() => loading = false);
    }
  }

  /* ================= FILTER ================= */

  Future<void> _applyFilter() async {
    List<Map<String, dynamic>> temp = [];

    for (var s in students) {
      final emailMatch = s['email'].toString().toLowerCase().contains(
        searchQuery.toLowerCase(),
      );

      final isFrozen = await FreezeService.isUserFrozen(email: s['email']);

      bool statusMatch = true;

      if (selectedFilter == "ACTIVE") {
        statusMatch = !isFrozen;
      } else if (selectedFilter == "FROZEN") {
        statusMatch = isFrozen;
      }

      if (emailMatch && statusMatch) {
        temp.add(s);
      }
    }

    setState(() {
      filtered = temp;
    });
  }

  /* ================= EXPIRY BADGE ================= */

  Widget _buildExpiryBadge(String? endDateStr) {
    if (endDateStr == null) return const SizedBox();

    final endDate = DateTime.tryParse(endDateStr);
    if (endDate == null) return const SizedBox();

    final today = DateTime.now();
    final diff = endDate.difference(today).inDays;

    if (diff < 0) {
      return _badge("Expired", Colors.red);
    } else if (diff <= 5) {
      return _badge("Expiring Soon", Colors.orange);
    }

    return const SizedBox();
  }

  Widget _badge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Freeze Membership"),
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
                            onChanged: (value) async {
                              searchQuery = value;
                              await _applyFilter();
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
                          ],
                          onChanged: (value) async {
                            selectedFilter = value!;
                            await _applyFilter();
                          },
                        ),
                      ],
                    ),
                  ),

                  /// LIST
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              "No students found",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filtered.length,
                            itemBuilder: (_, index) {
                              final s = filtered[index];

                              return FutureBuilder<bool>(
                                future: FreezeService.isUserFrozen(
                                  email: s['email'],
                                ),
                                builder: (context, snapshot) {
                                  final isFrozen = snapshot.data == true;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    decoration: BoxDecoration(
                                      color: isFrozen
                                          ? Colors.orange.shade50
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(
                                          0xFF4A6CF7,
                                        ),
                                        child: Text(
                                          s['seat'].toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        s['email'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text("Plan: ${s['months']} Months"),

                                          /// 🔥 Expiry Badge
                                          _buildExpiryBadge(s['endDate']),

                                          const SizedBox(height: 6),

                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isFrozen
                                                  ? Colors.orange
                                                  : Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              isFrozen ? "FROZEN" : "ACTIVE",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isFrozen
                                              ? Colors.grey
                                              : Colors.orange,
                                        ),
                                        onPressed: isFrozen
                                            ? null
                                            : () async {
                                                final result =
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            FreezeMembershipScreen(
                                                              email: s['email'],
                                                            ),
                                                      ),
                                                    );

                                                if (result == true) {
                                                  await _loadStudents();
                                                }
                                              },
                                        child: Text(
                                          isFrozen ? "Frozen" : "Freeze",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

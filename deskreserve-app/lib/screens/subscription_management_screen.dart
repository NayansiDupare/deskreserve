import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/booking_service.dart';
import '../services/upload_service.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  bool loading = true;

  List<Map<String, dynamic>> subscriptions = [];
  List<Map<String, dynamic>> filtered = [];

  String searchQuery = "";
  String selectedFilter = "ALL";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /* ================= LOAD ================= */

  Future<void> _loadData() async {
    try {
      setState(() => loading = true);

      final data = await BookingService.getAllSubscriptions();

      subscriptions = data;
      _applyFilter();

      if (mounted) {
        setState(() => loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  /* ================= FILTER ================= */

  void _applyFilter() {
    filtered = subscriptions.where((s) {
      final email = (s['email'] ?? "").toString().toLowerCase();
      final status = (s['status'] ?? "").toString().toUpperCase();

      final matchesSearch = email.contains(searchQuery.toLowerCase());
      final matchesFilter = selectedFilter == "ALL" || status == selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();

    if (mounted) setState(() {});
  }

  /* ================= EDIT ================= */

  void _showEditModal(Map<String, dynamic> sub) {
    final nameCtrl = TextEditingController(text: sub['student_name'] ?? '');
    final phoneCtrl = TextEditingController(text: sub['student_phone'] ?? '');
    final idTypeCtrl = TextEditingController(text: sub['id_proof_type'] ?? '');

    String? imageUrl = sub['id_proof_url'];
    File? selectedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text(
                      "Edit Subscription",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _input("Student Name", nameCtrl),
                    const SizedBox(height: 12),
                    _input("Phone Number", phoneCtrl),
                    const SizedBox(height: 12),
                    _input("ID Proof Type", idTypeCtrl),
                    const SizedBox(height: 12),

                    if (selectedImage != null)
                      Image.file(selectedImage!, height: 120)
                    else if (imageUrl != null && imageUrl!.isNotEmpty)
                      Image.network(imageUrl!, height: 120),

                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload),
                      label: const Text("Upload ID Proof"),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 70,
                        );

                        if (picked != null) {
                          selectedImage = File(picked.path);
                          setModalState(() {});
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () async {
                        /// 🔴 VALIDATION FIRST
                        if (nameCtrl.text.trim().isEmpty ||
                            phoneCtrl.text.trim().isEmpty ||
                            idTypeCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please fill all required details"),
                            ),
                          );
                          return;
                        }

                        try {
                          if (selectedImage != null) {
                            imageUrl = await UploadService.uploadIdProof(
                              selectedImage!,
                            );
                          }

                          await BookingService.updateSubscription(
                            email: sub['email'],
                            updates: {
                              "student_name": nameCtrl.text.trim(),
                              "student_phone": phoneCtrl.text.trim(),
                              "id_proof_type": idTypeCtrl.text.trim(),
                              "id_proof_url": imageUrl ?? "",
                            },
                          );

                          if (!mounted) return;

                          Navigator.pop(context);
                          await _loadData();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Subscription updated successfully",
                              ),
                            ),
                          );
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                      child: const Text("Save Changes"),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _input(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  /* ================= DELETE ================= */

  void _confirmDelete(String email) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text(
          "Are you sure you want to delete this subscription?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await BookingService.deleteSubscription(email: email);

              if (!mounted) return;

              Navigator.pop(context);
              await _loadData();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Subscription Management"),
          backgroundColor: const Color(0xFF4A6CF7),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
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
                                value: "DELETED",
                                child: Text("Deleted"),
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
                          ? const Center(
                              child: Text(
                                "No subscriptions found",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (_, index) {
                                final s = filtered[index];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    title: Text("Seat ${s['seat']}"),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(s['email']),
                                        Text("Plan: ${s['months']} Months"),
                                        Text("Status: ${s['status']}"),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => _showEditModal(s),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _confirmDelete(s['email']),
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

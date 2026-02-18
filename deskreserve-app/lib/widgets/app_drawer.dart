import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/login_screen.dart';
import '../screens/plan_selection_screen.dart';
import '../screens/my_bookings_screen.dart';
import '../screens/today_summary_screen.dart';
import '../screens/admin_analytics_screen.dart';
import '../screens/student_list_screen.dart';
import '../screens/freeze_student_selection_screen.dart';
import '../screens/subscription_management_screen.dart';

class AppDrawer extends StatelessWidget {
  final String role;

  const AppDrawer({super.key, required this.role});

  /// 🔹 Common navigation method (FIXES BACK ARROW ISSUE)
  void _navigate(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close drawer first
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // ================= HEADER =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
            color: const Color(0xFF4A6CF7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "DeskReserve",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Book. Study. Focus.",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // ================= SEAT BOOKING =================
          _drawerItem(
            context,
            icon: Icons.chair_alt_outlined,
            text: "Seat Booking",
            onTap: () => _navigate(context, const PlanSelectionScreen()),
          ),

          // ================= MY BOOKINGS =================
          _drawerItem(
            context,
            icon: Icons.schedule_outlined,
            text: "My Bookings",
            onTap: () => _navigate(context, const MyBookingsScreen()),
          ),

          // ================= TODAY SUMMARY =================
          _drawerItem(
            context,
            icon: Icons.today_outlined,
            text: "Today Summary",
            onTap: () => _navigate(context, const TodaySummaryScreen()),
          ),

          // ================= STUDENTS =================
          _drawerItem(
            context,
            icon: Icons.people_outline,
            text: "Students",
            onTap: () => _navigate(context, const StudentListScreen()),
          ),

          // ================= SUBSCRIPTION MANAGEMENT =================
          _drawerItem(
            context,
            icon: Icons.manage_accounts_outlined,
            text: "Subscription Management",
            onTap: () =>
                _navigate(context, const SubscriptionManagementScreen()),
          ),

          // ================= ANALYTICS =================
          _drawerItem(
            context,
            icon: Icons.analytics_outlined,
            text: "Analytics",
            onTap: () => _navigate(context, const AdminAnalyticsScreen()),
          ),

          const Spacer(),
          const Divider(),

          // ================= MEMBERSHIP FREEZE =================
          ListTile(
            leading: const Icon(Icons.ac_unit),
            title: const Text("Freeze Membership"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FreezeStudentSelectionScreen(),
                ),
              );
            },
          ),

          // ================= LOGOUT =================
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              "Logout",
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  /// 🔹 Drawer item builder
  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        text,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}

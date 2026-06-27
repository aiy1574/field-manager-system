import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'bookings_page.dart';
import 'create_booking_page.dart';
import 'customers_page.dart';
import 'fields_page.dart';
import 'products_page.dart';
import 'reports_page.dart';
import 'sales_history_page.dart';
import 'sell_products_page.dart';

const Color primaryGreen = Color(0xFF16A34A);
const Color darkGreen = Color(0xFF059669);
const Color lightBg = Color(0xFFF4F8F1);

class AdminHomePage extends StatefulWidget {
  final String token;
  final String role;

  const AdminHomePage({
    super.key,
    required this.token,
    required this.role,
  });

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int selectedIndex = 0;
  Map<String, dynamic> dashboard = {};

  bool get isOwner {
    return widget.role == 'owner' || widget.role == 'admin';
  }

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:4000/api/dashboard'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          dashboard = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Dashboard error: $e');
    }
  }

  void goToPage(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  Widget sidebarItem(String title, IconData icon, int index) {
    final selected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: ListTile(
        selected: selected,
        selectedTileColor: Colors.green.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        leading: Icon(
          icon,
          color: selected ? primaryGreen : Colors.black54,
        ),
        title: Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? primaryGreen : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          goToPage(index);
        },
      ),
    );
  }

  Widget summaryCard(
    String title,
    String value,
    IconData icon, {
    String? unit,
  }) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: SizedBox(
        width: 260,
        height: 140,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.green.shade100,
                child: Icon(
                  icon,
                  color: darkGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (unit != null)
                      Text(
                        unit,
                        style: const TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget dashboardPage() {
    final todayBookings = dashboard['today_bookings']?.toString() ?? '0';
    final todayRevenue = dashboard['today_revenue']?.toString() ?? '0';
    final pendingPayments = dashboard['pending_payments']?.toString() ?? '0';
    final checkedIn = dashboard['checked_in']?.toString() ?? '0';

    return Padding(
      padding: const EdgeInsets.all(28),
      child: ListView(
        children: [
          Row(
            children: [
              const Text(
                'ໜ້າຫຼັກ',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isOwner ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOwner
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                  ),
                ),
                child: Text(
                  isOwner ? 'Owner/Admin' : 'Staff',
                  style: TextStyle(
                    color: isOwner ? primaryGreen : Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: fetchDashboard,
                icon: const Icon(Icons.refresh),
                label: const Text('ໂຫຼດຄືນ'),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              summaryCard(
                'ການຈອງມື້ນີ້',
                todayBookings,
                Icons.calendar_month,
              ),
              summaryCard(
                'ລາຍຮັບ',
                todayRevenue,
                Icons.payments,
                unit: 'ກີບ',
              ),
              summaryCard(
                'ລໍຖ້າກວດສອບ',
                pendingPayments,
                Icons.hourglass_top,
              ),
              summaryCard(
                'ເຂົ້າໃຊ້ແລ້ວ',
                checkedIn,
                Icons.login,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Card(
            elevation: 2,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.green.shade50,
                    child: const Icon(
                      Icons.info_outline,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 18),
                  const Expanded(
                    child: Text(
                      'ພາບລວມຂອງລະບົບຈອງສະໜາມ ST: ຕິດຕາມການຈອງ, ການຊຳລະ, ລາຍຮັບ ແລະ ການເຂົ້າໃຊ້ສະໜາມ.',
                      style: TextStyle(
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget currentPage() {
    if (selectedIndex == 0) return dashboardPage();

    if (selectedIndex == 1 && isOwner) {
      return FieldsPage(token: widget.token);
    }

    if (selectedIndex == 2 && isOwner) {
      return CustomersPage(token: widget.token);
    }

    if (selectedIndex == 3) {
      return BookingsPage(token: widget.token);
    }

    if (selectedIndex == 4) {
      return CreateBookingPage(token: widget.token);
    }

    if (selectedIndex == 5 && isOwner) {
      return ProductsPage(token: widget.token);
    }

    if (selectedIndex == 6) {
      return SellProductsPage(token: widget.token);
    }

    if (selectedIndex == 7) {
      return SalesHistoryPage(token: widget.token);
    }

    if (selectedIndex == 8 && isOwner) {
      return ReportsPage(token: widget.token);
    }

    return dashboardPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      body: Row(
        children: [
          Container(
            width: 270,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Colors.grey.shade200),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 18,
                  offset: const Offset(4, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          primaryGreen,
                          darkGreen,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.sports_soccer,
                          color: Colors.white,
                          size: 34,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'ST Football\nAdmin',
                            style: TextStyle(
                              fontSize: 18,
                              height: 1.2,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                sidebarItem('ໜ້າຫຼັກ', Icons.dashboard, 0),

                if (isOwner)
                  sidebarItem('ຈັດການສະໜາມ', Icons.stadium, 1),

                if (isOwner)
                  sidebarItem('ລູກຄ້າ', Icons.people, 2),

                sidebarItem('ຈັດການການຈອງ', Icons.calendar_month, 3),
                sidebarItem('ຈອງເດີ່ນ', Icons.add_business, 4),

                if (isOwner)
                  sidebarItem('ສິນຄ້າ', Icons.shopping_cart, 5),

                sidebarItem('ຂາຍສິນຄ້າ', Icons.point_of_sale, 6),
                sidebarItem('ປະຫວັດການຂາຍ', Icons.history, 7),

                if (isOwner)
                  sidebarItem('ລາຍງານ', Icons.bar_chart, 8),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.all(14),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: const Icon(
                      Icons.logout,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'ອອກຈາກລະບົບ',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: lightBg,
              child: currentPage(),
            ),
          ),
        ],
      ),
    );
  }
}
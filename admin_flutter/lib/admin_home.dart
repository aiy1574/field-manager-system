import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'bookings_page.dart';
import 'create_booking_page.dart';
import 'customers_page.dart';
import 'fields_page.dart';
import 'products_page.dart';
import 'reports_page.dart';
import 'sell_products_page.dart';

class AdminHomePage extends StatefulWidget {
  final String token;

  const AdminHomePage({
    super.key,
    required this.token,
  });

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int selectedIndex = 0;
  Map dashboard = {};

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
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
  }

  Widget sidebarItem(String title, IconData icon, int index) {
    final selected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: ListTile(
        selected: selected,
        selectedTileColor: Colors.green.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Icon(
          icon,
          color: selected ? Colors.green : Colors.black54,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.green : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget summaryCard(String title, String value, IconData icon, {String? unit}) {
    return Card(
      elevation: 3,
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
                child: Icon(icon, color: Colors.green.shade800),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
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
                'Dashboard',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: fetchDashboard,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              summaryCard('Today Bookings', todayBookings, Icons.calendar_month),
              summaryCard('Revenue', todayRevenue, Icons.payments, unit: 'Kip'),
              summaryCard('Pending Payments', pendingPayments, Icons.hourglass_top),
              summaryCard('Checked-in', checkedIn, Icons.login),
            ],
          ),
        ],
      ),
    );
  }

  Widget currentPage() {
    if (selectedIndex == 0) return dashboardPage();
    if (selectedIndex == 1) return FieldsPage(token: widget.token);
    if (selectedIndex == 2) return CustomersPage(token: widget.token);
    if (selectedIndex == 3) return BookingsPage(token: widget.token);
    if (selectedIndex == 4) return ProductsPage(token: widget.token);
    if (selectedIndex == 5) return SellProductsPage(token: widget.token);
    if (selectedIndex == 6) return ReportsPage(token: widget.token);

    return dashboardPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      const Icon(Icons.sports_soccer, color: Colors.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ເຂົ້າສູ່ລະບົບເດີ່ນບານ ST',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                sidebarItem('Dashboard', Icons.dashboard, 0),
                sidebarItem('Field Management', Icons.stadium, 1),
                sidebarItem('Customers', Icons.people, 2),
                sidebarItem('Bookings', Icons.calendar_month, 3),
                sidebarItem('Products', Icons.shopping_cart, 4),
                sidebarItem('POS System', Icons.point_of_sale, 5),
                sidebarItem('Reports', Icons.bar_chart, 6),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.all(14),
                  child: ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              color: const Color(0xFFF8FCF5),
              child: currentPage(),
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReportsPage extends StatefulWidget {
  final String token;

  const ReportsPage({
    super.key,
    required this.token,
  });

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  Map summary = {};
  List revenueList = [];
  bool loading = true;

  Future<void> fetchReports() async {
    final response = await http.get(
      Uri.parse('http://localhost:4000/api/reports'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        summary = data['summary'] ?? {};
        revenueList = data['revenue_list'] ?? [];
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Widget reportCard(String title, String value, IconData icon) {
    return Card(
      elevation: 3,
      child: SizedBox(
        width: 240,
        height: 120,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Icon(icon, color: Colors.green),
              ),
              const SizedBox(width: 15),
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
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  String formatDate(dynamic value) {
    if (value == null) return '-';
    final text = value.toString();
    if (text.length >= 10) return text.substring(0, 10);
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue = summary['total_revenue']?.toString() ?? '0';
    final todayRevenue = summary['today_revenue']?.toString() ?? '0';
    final totalBookings = summary['total_bookings']?.toString() ?? '0';
    final paidBookings = summary['paid_bookings']?.toString() ?? '0';
    final pendingPayments = summary['pending_payments']?.toString() ?? '0';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports & Revenue"),
        actions: [
          IconButton(
            onPressed: fetchReports,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(25),
              child: ListView(
                children: [
                  const Text(
                    "Reports & Revenue",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Wrap(
                    spacing: 18,
                    runSpacing: 18,
                    children: [
                      reportCard(
                        "Total Revenue",
                        "$totalRevenue Kip",
                        Icons.payments,
                      ),
                      reportCard(
                        "Today Revenue",
                        "$todayRevenue Kip",
                        Icons.today,
                      ),
                      reportCard(
                        "Total Bookings",
                        totalBookings,
                        Icons.calendar_month,
                      ),
                      reportCard(
                        "Paid Bookings",
                        paidBookings,
                        Icons.check_circle,
                      ),
                      reportCard(
                        "Pending Payments",
                        pendingPayments,
                        Icons.hourglass_top,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Revenue List",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Card(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text("Date")),
                          DataColumn(label: Text("Field")),
                          DataColumn(label: Text("Customer")),
                          DataColumn(label: Text("Time")),
                          DataColumn(label: Text("Price")),
                          DataColumn(label: Text("Payment")),
                          DataColumn(label: Text("Status")),
                        ],
                        rows: revenueList.map((item) {
                          return DataRow(
                            cells: [
                              DataCell(Text(formatDate(item['booking_date']))),
                              DataCell(Text(item['field_name'] ?? '-')),
                              DataCell(Text(item['customer_name'] ?? '-')),
                              DataCell(
                                Text(
                                  "${item['start_time']} - ${item['end_time']}",
                                ),
                              ),
                              DataCell(Text("${item['total_price']}")),
                              DataCell(Text(item['payment_status'] ?? '-')),
                              DataCell(Text(item['status'] ?? '-')),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

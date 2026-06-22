import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'booking_page.dart';

class DashboardPage extends StatefulWidget {
  final String token;
  final Map customer;

  const DashboardPage({
    super.key,
    required this.token,
    required this.customer,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        token: widget.token,
        customer: widget.customer,
      ),
      BookingHistoryPage(
        token: widget.token,
        customer: widget.customer,
      ),
      ProfilePage(customer: widget.customer),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Football Booking"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.green,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "History",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String token;
  final Map customer;

  const HomePage({
    super.key,
    required this.token,
    required this.customer,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List fields = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadFields();
  }

  Future<void> loadFields() async {
    final response = await http.get(
      Uri.parse('http://localhost:4000/api/fields'),
    );

    if (response.statusCode == 200) {
      setState(() {
        fields = jsonDecode(response.body);
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (fields.isEmpty) {
      return const Center(
        child: Text("No fields found"),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: fields.length,
      itemBuilder: (context, index) {
        final field = fields[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(
                Icons.sports_soccer,
                color: Colors.white,
              ),
            ),
            title: Text(
              field['name'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              field['description'] ?? '',
            ),
            trailing: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingPage(
                      token: widget.token,
                      customer: widget.customer,
                      field: field,
                    ),
                  ),
                );
              },
              child: const Text("Book"),
            ),
          ),
        );
      },
    );
  }
}

class BookingHistoryPage extends StatefulWidget {
  final String token;
  final Map customer;

  const BookingHistoryPage({
    super.key,
    required this.token,
    required this.customer,
  });

  @override
  State<BookingHistoryPage> createState() =>
      _BookingHistoryPageState();
}

class _BookingHistoryPageState
    extends State<BookingHistoryPage> {
  List bookings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    final response = await http.get(
      Uri.parse('http://localhost:4000/api/bookings'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final allBookings = jsonDecode(response.body);

      setState(() {
        bookings = allBookings
            .where(
              (b) =>
                  b['customer_id'] ==
                  widget.customer['id'],
            )
            .toList();

        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  Color statusColor(String? status) {
    if (status == 'checked_in') {
      return Colors.green;
    }

    if (status == 'cancelled') {
      return Colors.red;
    }

    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (bookings.isEmpty) {
      return const Center(
        child: Text('No booking history'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];

        return Card(
          margin:
              const EdgeInsets.only(bottom: 15),
          child: ListTile(
            leading: Icon(
              Icons.calendar_month,
              color: statusColor(
                booking['status'],
              ),
            ),
            title: Text(
              booking['field_name'] ?? '',
            ),
            subtitle: Text(
              'Date: ${booking['booking_date'].toString().substring(0, 10)}\n'
              'Time: ${booking['start_time']} - ${booking['end_time']}\n'
              'Status: ${booking['status']}',
            ),
          ),
        );
      },
    );
  }
}

class ProfilePage extends StatelessWidget {
  final Map customer;

  const ProfilePage({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.person,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              Text(
                "Name : ${customer['full_name'] ?? ''}",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                "Phone : ${customer['phone'] ?? ''}",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                "Email : ${customer['email'] ?? ''}",
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
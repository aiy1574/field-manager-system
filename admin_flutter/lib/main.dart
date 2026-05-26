import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'bookings_page.dart';
import 'create_booking_page.dart';
import 'fields_page.dart';
import 'products_page.dart';
import 'sell_products_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> login(BuildContext context) async {
    final response = await http.post(
      Uri.parse(
        'http://localhost:4000/api/auth/login',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': emailController.text,
        'password': passwordController.text,
      }),
    );

    print(response.body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final token = data['token'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardPage(token: token),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          child: Card(
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.sports_soccer,
                    size: 80,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Football Admin",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => login(context),
                      child: const Text(
                        "Login",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  final String token;

  const DashboardPage({
    super.key,
    required this.token,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map dashboard = {};

  Future<void> fetchDashboard() async {
    final response = await http.get(
      Uri.parse(
        'http://localhost:4000/api/dashboard',
      ),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    print(response.body);

    if (response.statusCode == 200) {
      setState(() {
        dashboard = jsonDecode(response.body);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Widget summaryCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      elevation: 5,
      child: SizedBox(
        width: 250,
        height: 130,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                child: Icon(
                  icon,
                  size: 30,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
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

  Widget menuButton(
    String title,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: 300,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayBookings = dashboard['today_bookings']?.toString() ?? '0';

    final todayRevenue = dashboard['today_revenue']?.toString() ?? '0';

    final unpaidBookings = dashboard['unpaid_bookings']?.toString() ?? '0';

    final checkedIn = dashboard['checked_in']?.toString() ?? '0';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Football Admin Dashboard",
        ),
        actions: [
          IconButton(
            onPressed: fetchDashboard,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: ListView(
          children: [
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                summaryCard(
                  "Today Bookings",
                  todayBookings,
                  Icons.calendar_today,
                ),
                summaryCard(
                  "Revenue",
                  "$todayRevenue Kip",
                  Icons.payments,
                ),
                summaryCard(
                  "Unpaid",
                  unpaidBookings,
                  Icons.warning,
                ),
                summaryCard(
                  "Checked-in",
                  checkedIn,
                  Icons.login,
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Text(
              "Management",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                menuButton(
                  "Manage Fields",
                  Icons.stadium,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FieldsPage(
                          token: widget.token,
                        ),
                      ),
                    );
                  },
                ),
                menuButton(
                  "View Bookings",
                  Icons.list_alt,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingsPage(
                          token: widget.token,
                        ),
                      ),
                    );
                  },
                ),
                menuButton(
                  "Create Booking",
                  Icons.add_box,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateBookingPage(
                          token: widget.token,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                menuButton(
                  "Manage Products",
                  Icons.shopping_cart,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductsPage(
                          token: widget.token,
                        ),
                      ),
                    );
                  },
                ),
                menuButton(
                  "Sell Products",
                  Icons.point_of_sale,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SellProductsPage(
                          token: widget.token,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

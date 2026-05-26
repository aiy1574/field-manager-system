import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'bookings_page.dart';
import 'create_booking_page.dart';

import 'fields_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      Uri.parse('http://localhost:4000/api/auth/login'),
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
      appBar: AppBar(
        title: const Text("Admin Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => login(context),
              child: const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
class DashboardPage extends StatelessWidget {
  final String token;

  const DashboardPage({
    super.key,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FieldsPage(token: token),
                  ),
                );
              },
              child: const Text("Manage Fields"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BookingsPage(token: token),
                  ),
                );
              },
              child: const Text("View Bookings"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateBookingPage(token: token),
                  ),
                );
              },
              child: const Text("Create Booking"),
            ),
          ],
        ),
      ),
    );
  }
}
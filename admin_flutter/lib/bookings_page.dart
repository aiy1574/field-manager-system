import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BookingsPage extends StatefulWidget {
  final String token;

  const BookingsPage({
    super.key,
    required this.token,
  });

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  List bookings = [];

  Future<void> fetchBookings() async {
    final response = await http.get(
      Uri.parse('http://localhost:4000/api/bookings'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    print(response.body);

    if (response.statusCode == 200) {
      setState(() {
        bookings = jsonDecode(response.body);
      });
    }
  }

  Future<void> markPaid(int id) async {
    await http.patch(
      Uri.parse(
        'http://localhost:4000/api/bookings/$id/pay',
      ),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    fetchBookings();
  }

  Future<void> checkIn(int id) async {
    await http.patch(
      Uri.parse(
        'http://localhost:4000/api/bookings/$id/checkin',
      ),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    fetchBookings();
  }

  Future<void> cancelBooking(int id) async {
    await http.patch(
      Uri.parse(
        'http://localhost:4000/api/bookings/$id/cancel',
      ),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    fetchBookings();
  }

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bookings"),
        actions: [
          IconButton(
            onPressed: fetchBookings,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView.builder(
          itemCount: bookings
              .where((booking) => booking['status'] != 'cancelled')
              .length,
          itemBuilder: (context, index) {
            final activeBookings = bookings
              .where((booking) => booking['status'] != 'cancelled')
              .toList();

            final booking = activeBookings[index];
            
            final paid =
                booking['paid'] == 1 ||
                booking['paid'] == true;

            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['field_name'] ??
                          'Unknown Field',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Customer: ${booking['customer_name'] ?? '-'}',
                    ),

                    Text(
                      'Phone: ${booking['customer_phone'] ?? '-'}',
                    ),

                    Text(
                      'Date: ${booking['booking_date']}',
                    ),

                    Text(
                      'Time: ${booking['start_time']} - ${booking['end_time']}',
                    ),

                    Text(
                      'Price: ${booking['total_price'] ?? '-'}',
                    ),

                    Text(
                      'Paid: ${paid ? "Yes" : "No"}',
                    ),

                    Text(
                      'Status: ${booking['status']}',
                    ),

                    const SizedBox(height: 15),

                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: paid
                              ? null
                              : () {
                                  markPaid(
                                    booking['id'],
                                  );
                                },
                          child: const Text("Paid"),
                        ),

                        const SizedBox(width: 10),

                        ElevatedButton(
                          onPressed:
                              booking['status'] ==
                                      'checked_in'
                                  ? null
                                  : () {
                                      checkIn(
                                        booking['id'],
                                      );
                                    },
                          child: const Text(
                            "Check-in",
                          ),
                        ),

                        const SizedBox(width: 10),

                        ElevatedButton(
                          onPressed:
                              booking['status'] ==
                                      'cancelled'
                                  ? null
                                  : () {
                                      cancelBooking(
                                        booking['id'],
                                      );
                                    },
                          child: const Text(
                            "Cancel",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
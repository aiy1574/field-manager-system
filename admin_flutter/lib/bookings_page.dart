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

  String filter = 'active';

<<<<<<< HEAD
  final dateController = TextEditingController();

=======
>>>>>>> 6a2acde199626aec73368ff41309d7b67f8513a5
  Future<void> fetchBookings() async {
    final response = await http.get(
      Uri.parse(
        'http://localhost:4000/api/bookings?date=${dateController.text}',
      ),
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

  List getFilteredBookings() {
    if (filter == 'all') {
      return bookings;
    }

    if (filter == 'active') {
      return bookings
          .where(
            (booking) => booking['status'] != 'cancelled',
          )
          .toList();
    }

    if (filter == 'paid') {
      return bookings
          .where(
            (booking) =>
                booking['paid'] == 1 ||
                booking['paid'] == true,
          )
          .toList();
    }

    if (filter == 'unpaid') {
      return bookings
          .where(
            (booking) =>
                booking['paid'] != 1 &&
                booking['paid'] != true &&
                booking['status'] != 'cancelled',
          )
          .toList();
    }

    if (filter == 'cancelled') {
      return bookings
          .where(
            (booking) => booking['status'] == 'cancelled',
          )
          .toList();
    }

    return bookings;
  }

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    dateController.text =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    fetchBookings();
  }

  Widget filterButton(String label, String value) {
    final isSelected = filter == value;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          filter = value;
        });
      },
      child: Text(
        isSelected ? "✓ $label" : label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredBookings = getFilteredBookings();

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
        child: Column(
          children: [
<<<<<<< HEAD
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Filter Date",
                suffixIcon: Icon(Icons.calendar_month),
              ),
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                );

                if (pickedDate != null) {
                  dateController.text =
                      "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";

                  fetchBookings();
                }
              },
            ),

            const SizedBox(height: 15),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  filterButton("All", "all"),
                  const SizedBox(width: 10),
                  filterButton("Active", "active"),
                  const SizedBox(width: 10),
                  filterButton("Paid", "paid"),
                  const SizedBox(width: 10),
                  filterButton("Unpaid", "unpaid"),
                  const SizedBox(width: 10),
                  filterButton("Cancelled", "cancelled"),
                ],
              ),
            ),

            const SizedBox(height: 20),

=======
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  filterButton("All", "all"),
                  const SizedBox(width: 10),
                  filterButton("Active", "active"),
                  const SizedBox(width: 10),
                  filterButton("Paid", "paid"),
                  const SizedBox(width: 10),
                  filterButton("Unpaid", "unpaid"),
                  const SizedBox(width: 10),
                  filterButton("Cancelled", "cancelled"),
                ],
              ),
            ),

            const SizedBox(height: 20),

>>>>>>> 6a2acde199626aec73368ff41309d7b67f8513a5
            Expanded(
              child: ListView.builder(
                itemCount: filteredBookings.length,
                itemBuilder: (context, index) {
                  final booking = filteredBookings[index];

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
          ],
        ),
      ),
    );
  }
}
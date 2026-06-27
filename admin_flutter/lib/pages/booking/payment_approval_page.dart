import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PaymentApprovalPage extends StatefulWidget {
  final String token;

  const PaymentApprovalPage({
    super.key,
    required this.token,
  });

  @override
  State<PaymentApprovalPage> createState() => _PaymentApprovalPageState();
}

class _PaymentApprovalPageState extends State<PaymentApprovalPage> {
  List bookings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  Future<void> loadBookings() async {
    final response = await http.get(
      Uri.parse('http://localhost:4000/api/bookings'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        bookings = data.where((b) {
          return b['slip_image'] != null &&
              b['slip_image'].toString().isNotEmpty;
        }).toList();

        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> approveBooking(int id) async {
    await http.patch(
      Uri.parse('http://localhost:4000/api/bookings/$id/approve-payment'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    loadBookings();
  }

  Future<void> rejectBooking(int id) async {
    await http.patch(
      Uri.parse('http://localhost:4000/api/bookings/$id/reject-payment'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    loadBookings();
  }

  Color statusColor(String? status) {
    if (status == 'paid') return Colors.green;
    if (status == 'rejected') return Colors.red;
    return Colors.orange;
  }

  String statusText(String? status) {
    if (status == 'paid') return 'Approved';
    if (status == 'rejected') return 'Rejected';
    return 'Pending';
  }

  String formatDate(dynamic value) {
    if (value == null) return '-';
    final text = value.toString();
    if (text.length >= 10) return text.substring(0, 10);
    return text;
  }

  String formatTime(dynamic value) {
    if (value == null) return '-';
    final text = value.toString();
    if (text.length >= 5) return text.substring(0, 5);
    return text;
  }

  String slipUrl(String path) {
    if (path.startsWith('http')) return path;
    return 'http://localhost:4000/$path';
  }

  Widget bookingCard(Map booking) {
    final paymentStatus = booking['payment_status']?.toString() ?? 'pending';
    final slip = booking['slip_image']?.toString();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (slip != null && slip.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  slipUrl(slip),
                  width: 220,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 220,
                      height: 220,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Text('Slip not found'),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking['field_name'] ?? '-',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Customer: ${booking['customer_name'] ?? '-'}'),
                  const SizedBox(height: 6),
                  Text('Phone: ${booking['customer_phone'] ?? '-'}'),
                  const SizedBox(height: 6),
                  Text('Date: ${formatDate(booking['booking_date'])}'),
                  const SizedBox(height: 6),
                  Text(
                    'Time: ${formatTime(booking['start_time'])} - ${formatTime(booking['end_time'])}',
                  ),
                  const SizedBox(height: 6),
                  Text('Amount: ${booking['total_price'] ?? 0} Kip'),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor(paymentStatus).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      statusText(paymentStatus),
                      style: TextStyle(
                        color: statusColor(paymentStatus),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: paymentStatus == 'paid'
                            ? null
                            : () {
                                approveBooking(booking['id']);
                              },
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: paymentStatus == 'rejected'
                            ? null
                            : () {
                                rejectBooking(booking['id']);
                              },
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Payment Approval',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: loadBookings,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: bookings.isEmpty
                ? const Center(
                    child: Text('No payment slips found'),
                  )
                : ListView(
                    children: bookings.map((booking) {
                      return bookingCard(booking);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

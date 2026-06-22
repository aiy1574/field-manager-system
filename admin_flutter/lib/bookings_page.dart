import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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
  bool loading = true;

  final dateController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    dateController.text =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    fetchBookings();
  }

  Future<void> fetchBookings() async {
    setState(() {
      loading = true;
    });

    String url = 'http://localhost:4000/api/bookings';

    if (filter != 'all') {
      url += '?date=${dateController.text}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        bookings = jsonDecode(response.body);
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> approvePayment(int id) async {
    await http.patch(
      Uri.parse('http://localhost:4000/api/bookings/$id/approve-payment'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    fetchBookings();
  }

  Future<void> rejectPayment(int id) async {
    await http.patch(
      Uri.parse('http://localhost:4000/api/bookings/$id/reject-payment'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    fetchBookings();
  }

  Future<void> markPaid(int id) async {
    await http.patch(
      Uri.parse('http://localhost:4000/api/bookings/$id/pay'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    fetchBookings();
  }

  Future<void> checkIn(int id) async {
    await http.patch(
      Uri.parse('http://localhost:4000/api/bookings/$id/checkin'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    fetchBookings();
  }

  Future<void> cancelBooking(int id) async {
    await http.patch(
      Uri.parse('http://localhost:4000/api/bookings/$id/cancel'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    fetchBookings();
  }

  Future<void> openSlip(String path) async {
    final cleanPath = path.replaceAll('\\', '/');
    final url = 'http://localhost:4000/$cleanPath';

    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }

  List getFilteredBookings() {
    if (filter == 'all') return bookings;

    if (filter == 'active') {
      return bookings.where((b) => b['status'] != 'cancelled').toList();
    }

    if (filter == 'paid') {
      return bookings.where((b) => b['payment_status'] == 'paid').toList();
    }

    if (filter == 'pending') {
      return bookings.where((b) => b['payment_status'] == 'pending').toList();
    }

    if (filter == 'rejected') {
      return bookings.where((b) => b['payment_status'] == 'rejected').toList();
    }

    if (filter == 'cancelled') {
      return bookings.where((b) => b['status'] == 'cancelled').toList();
    }

    return bookings;
  }

  String formatDate(dynamic value) {
    if (value == null) return '-';
    final text = value.toString();
    if (text.length >= 10) return text.substring(0, 10);
    return text;
  }

  Color statusColor(String? status) {
    if (status == 'checked_in') return Colors.green;
    if (status == 'cancelled') return Colors.red;
    return Colors.orange;
  }

  Color paymentColor(String? status) {
    if (status == 'paid') return Colors.green;
    if (status == 'rejected') return Colors.red;
    return Colors.orange;
  }

  Widget badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget filterButton(String label, String value) {
    final selected = filter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
        height: 42,
        child: ChoiceChip(
          selected: selected,
          label: Text(
            selected ? "✓ $label" : label,
            overflow: TextOverflow.ellipsis,
          ),
          onSelected: (_) {
            setState(() {
              filter = value;
            });
            fetchBookings();
          },
        ),
      ),
    );
  }

  void showManageDialog(Map booking) {
    final id = booking['id'];
    final paymentStatus = booking['payment_status']?.toString() ?? 'pending';
    final status = booking['status']?.toString() ?? 'booked';
    final slipImage = booking['slip_image'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Manage Booking #$id"),
          content: SizedBox(
            width: 430,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.sports_soccer),
                  title: Text(booking['field_name'] ?? '-'),
                  subtitle: Text(
                    "${formatDate(booking['booking_date'])} | ${booking['start_time']} - ${booking['end_time']}",
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(booking['customer_name'] ?? '-'),
                  subtitle: Text(booking['customer_phone'] ?? '-'),
                ),
                ListTile(
                  leading: const Icon(Icons.payments),
                  title: Text("${booking['total_price']} Kip"),
                  subtitle: Text("Payment: $paymentStatus"),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (slipImage != null && slipImage.toString().isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () => openSlip(slipImage),
                        icon: const Icon(Icons.receipt),
                        label: const Text("View Slip"),
                      ),
                    ElevatedButton(
                      onPressed: paymentStatus == 'paid'
                          ? null
                          : () {
                              Navigator.pop(context);
                              approvePayment(id);
                            },
                      child: const Text("Approve"),
                    ),
                    ElevatedButton(
                      onPressed: paymentStatus == 'rejected'
                          ? null
                          : () {
                              Navigator.pop(context);
                              rejectPayment(id);
                            },
                      child: const Text("Reject"),
                    ),
                    ElevatedButton(
                      onPressed: paymentStatus == 'paid'
                          ? null
                          : () {
                              Navigator.pop(context);
                              markPaid(id);
                            },
                      child: const Text("Paid"),
                    ),
                    ElevatedButton(
                      onPressed: status == 'checked_in'
                          ? null
                          : () {
                              Navigator.pop(context);
                              checkIn(id);
                            },
                      child: const Text("Check-in"),
                    ),
                    ElevatedButton(
                      onPressed: status == 'cancelled'
                          ? null
                          : () {
                              Navigator.pop(context);
                              cancelBooking(id);
                            },
                      child: const Text("Cancel"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredBookings = getFilteredBookings();

    return Padding(
      padding: const EdgeInsets.all(34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Booking Management",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: fetchBookings,
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh"),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              elevation: 3,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 260,
                          child: TextField(
                            controller: dateController,
                            readOnly: true,
                            enabled: filter != 'all',
                            decoration: InputDecoration(
                              labelText: filter == 'all'
                                  ? "All booking history"
                                  : "Filter Date",
                              prefixIcon: const Icon(Icons.calendar_month),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onTap: filter == 'all'
                                ? null
                                : () async {
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
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                filterButton("All", "all"),
                                filterButton("Active", "active"),
                                filterButton("Pending", "pending"),
                                filterButton("Paid", "paid"),
                                filterButton("Rejected", "rejected"),
                                filterButton("Cancelled", "cancelled"),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredBookings.isEmpty
                            ? const Center(child: Text("No bookings found"))
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 1400,
                                  ),
                                  child: SingleChildScrollView(
                                    child: DataTable(
                                      headingRowHeight: 58,
                                      dataRowMinHeight: 70,
                                      dataRowMaxHeight: 86,
                                      columns: const [
                                        DataColumn(label: Text("Booking ID")),
                                        DataColumn(label: Text("Customer")),
                                        DataColumn(label: Text("Field")),
                                        DataColumn(label: Text("Date & Time")),
                                        DataColumn(label: Text("Amount")),
                                        DataColumn(label: Text("Status")),
                                        DataColumn(label: Text("Payment")),
                                        DataColumn(label: Text("Action")),
                                      ],
                                      rows: filteredBookings.map((booking) {
                                        final paymentStatus =
                                            booking['payment_status']
                                                    ?.toString() ??
                                                'pending';
                                        final status =
                                            booking['status']?.toString() ??
                                                'booked';

                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              SizedBox(
                                                width: 90,
                                                child: Text(
                                                  "BK-${booking['id']}",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color:
                                                        Colors.green.shade800,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 190,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      booking['customer_name'] ??
                                                          '-',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    Text(
                                                      booking['customer_phone'] ??
                                                          '-',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 160,
                                                child: Text(
                                                  booking['field_name'] ?? '-',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 190,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(formatDate(
                                                        booking[
                                                            'booking_date'])),
                                                    Text(
                                                      "${booking['start_time']} - ${booking['end_time']}",
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 110,
                                                child: Text(
                                                  "${booking['total_price']}",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 130,
                                                child: badge(
                                                  status,
                                                  statusColor(status),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 130,
                                                child: badge(
                                                  paymentStatus,
                                                  paymentColor(paymentStatus),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 100,
                                                child: TextButton(
                                                  onPressed: () {
                                                    showManageDialog(booking);
                                                  },
                                                  child: const Text("Manage"),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Showing ${filteredBookings.length} of ${bookings.length} bookings",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text("Prev"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text("1"),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text("Next"),
                        ),
                      ],
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
}
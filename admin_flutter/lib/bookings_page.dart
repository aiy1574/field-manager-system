import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const Color primaryGreen = Color(0xFF16A34A);
const Color lightBg = Color(0xFFF4F8F1);

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

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  void showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : primaryGreen,
      ),
    );
  }

  Future<void> fetchBookings() async {
    setState(() {
      loading = true;
    });

    String url = 'http://localhost:4000/api/bookings';

    final useDate = filter != 'all' && filter != 'cancel_requested';

    if (useDate) {
      url += '?date=${dateController.text}';
    }

    try {
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
        showMessage('ບໍ່ສາມາດໂຫຼດການຈອງໄດ້', error: true);
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      showMessage('ເຊື່ອມຕໍ່ Server ບໍ່ໄດ້', error: true);
    }
  }

  Future<void> doPatch(String path, String successMessage) async {
    try {
      final response = await http.patch(
        Uri.parse('http://localhost:4000/api/bookings/$path'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        showMessage(successMessage);
        await fetchBookings();
      } else {
        String message = 'ດຳເນີນການບໍ່ສຳເລັດ';

        try {
          final data = jsonDecode(response.body);
          message = data['message'] ?? message;
        } catch (_) {
          message = response.body.isEmpty ? message : response.body;
        }

        showMessage(message, error: true);
      }
    } catch (e) {
      showMessage('ເຊື່ອມຕໍ່ Server ບໍ່ໄດ້', error: true);
    }
  }

  Future<void> approvePayment(int id) async {
    await doPatch('$id/approve-payment', 'ອະນຸມັດການຊຳລະສຳເລັດ');
  }

  Future<void> rejectPayment(int id) async {
    await doPatch('$id/reject-payment', 'ປະຕິເສດການຊຳລະສຳເລັດ');
  }

  Future<void> partialPayment(int id) async {
    await doPatch('$id/partial-payment', 'ບັນທຶກຈ່າຍບໍ່ຄົບສຳເລັດ');
  }

  Future<void> markPaid(int id) async {
    await doPatch('$id/pay', 'ຊຳລະເງິນສົດສຳເລັດ');
  }

  Future<void> checkIn(int id) async {
    await doPatch('$id/checkin', 'Check-in ສຳເລັດ');
  }

  Future<void> cancelBooking(int id) async {
    await doPatch('$id/cancel', 'ຍົກເລີກການຈອງສຳເລັດ');
  }

  Future<void> approveCancelRequest(int id) async {
    await doPatch('$id/approve-cancel', 'ອະນຸມັດຍົກເລີກສຳເລັດ');
  }

  Future<void> rejectCancelRequest(int id) async {
    await doPatch('$id/reject-cancel', 'ປະຕິເສດຄຳຂໍຍົກເລີກສຳເລັດ');
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

    if (filter == 'partial') {
      return bookings.where((b) => b['payment_status'] == 'partial').toList();
    }

    if (filter == 'pending') {
      return bookings.where((b) => b['payment_status'] == 'pending').toList();
    }

    if (filter == 'rejected') {
      return bookings.where((b) => b['payment_status'] == 'rejected').toList();
    }

    if (filter == 'cancel_requested') {
      return bookings.where((b) => b['status'] == 'cancel_requested').toList();
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

  String formatTime(dynamic value) {
    if (value == null) return '-';
    final text = value.toString();
    if (text.length >= 5) return text.substring(0, 5);
    return text;
  }

  String formatPrice(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    String text;

    if (number == number.roundToDouble()) {
      text = number.toInt().toString();
    } else {
      text = number.toStringAsFixed(2);
    }

    text = text.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    return '$text ກີບ';
  }

  String laoStatus(String status) {
    switch (status) {
      case 'booked':
        return 'ຈອງແລ້ວ';
      case 'checked_in':
        return 'ເຂົ້າໃຊ້ແລ້ວ';
      case 'cancelled':
        return 'ຍົກເລີກແລ້ວ';
      case 'cancel_requested':
        return 'ຂໍຍົກເລີກ';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  String laoPayment(String status) {
    switch (status) {
      case 'pending':
        return 'ລໍຖ້າກວດສອບ';
      case 'paid':
        return 'ຊຳລະແລ້ວ';
      case 'partial':
        return 'ຈ່າຍບໍ່ຄົບ';
      case 'rejected':
        return 'ປະຕິເສດ';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  Color statusColor(String? status) {
    if (status == 'checked_in') return Colors.green;
    if (status == 'cancelled') return Colors.red;
    if (status == 'cancel_requested') return Colors.deepOrange;
    return Colors.orange;
  }

  Color paymentColor(String? status) {
    if (status == 'paid') return Colors.green;
    if (status == 'partial') return Colors.deepOrange;
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
          selectedColor: Colors.green.shade100,
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

  Widget actionButton({
    required String text,
    required VoidCallback? onPressed,
    required IconData icon,
    Color color = primaryGreen,
    bool outlined = false,
  }) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  Future<void> confirmAction({
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
    Color color = primaryGreen,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ບໍ່'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ຢືນຢັນ'),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      await onConfirm();
    }
  }

  void showManageDialog(Map booking) {
    final id = int.tryParse(booking['id'].toString()) ?? 0;
    final paymentStatus = booking['payment_status']?.toString() ?? 'pending';
    final status = booking['status']?.toString() ?? 'booked';
    final slipImage = booking['slip_image'];
    final hasSlip = slipImage != null && slipImage.toString().isNotEmpty;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: lightBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "ຈັດການການຈອງ #$id",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.sports_soccer),
                    title: Text(booking['field_name'] ?? '-'),
                    subtitle: Text(
                      "${formatDate(booking['booking_date'])} | "
                      "${formatTime(booking['start_time'])} - ${formatTime(booking['end_time'])}",
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(booking['customer_name'] ?? '-'),
                    subtitle: Text(booking['customer_phone'] ?? '-'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.payments),
                    title: Text(formatPrice(booking['total_price'] ?? 0)),
                    subtitle: Text("ການຊຳລະ: ${laoPayment(paymentStatus)}"),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      badge(laoStatus(status), statusColor(status)),
                      const SizedBox(width: 10),
                      badge(laoPayment(paymentStatus), paymentColor(paymentStatus)),
                    ],
                  ),
                  if (status == 'cancel_requested') ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.deepOrange.withOpacity(0.35),
                        ),
                      ),
                      child: const Text(
                        'ລູກຄ້າໄດ້ສົ່ງຄຳຂໍຍົກເລີກການຈອງນີ້',
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  const Text(
                    'ຈັດການການຊຳລະ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      actionButton(
                        text: 'ເບິ່ງສະລິບ',
                        icon: Icons.receipt_long,
                        outlined: true,
                        onPressed: hasSlip
                            ? () {
                                openSlip(slipImage.toString());
                              }
                            : null,
                      ),
                      actionButton(
                        text: 'ອະນຸມັດ',
                        icon: Icons.check_circle,
                        color: primaryGreen,
                        onPressed: paymentStatus == 'paid' ||
                                status == 'cancelled'
                            ? null
                            : () {
                                Navigator.pop(context);
                                approvePayment(id);
                              },
                      ),
                      actionButton(
                        text: 'ຈ່າຍບໍ່ຄົບ',
                        icon: Icons.warning_amber_rounded,
                        color: Colors.deepOrange,
                        onPressed: paymentStatus == 'partial' ||
                                status == 'cancelled'
                            ? null
                            : () {
                                Navigator.pop(context);
                                partialPayment(id);
                              },
                      ),
                      actionButton(
                        text: 'ປະຕິເສດ',
                        icon: Icons.cancel,
                        color: Colors.red,
                        onPressed: paymentStatus == 'rejected' ||
                                status == 'cancelled'
                            ? null
                            : () {
                                Navigator.pop(context);
                                rejectPayment(id);
                              },
                      ),
                      actionButton(
                        text: 'ຊຳລະເງິນສົດ',
                        icon: Icons.payments,
                        outlined: true,
                        onPressed: paymentStatus == 'paid' ||
                                status == 'cancelled'
                            ? null
                            : () {
                                Navigator.pop(context);
                                markPaid(id);
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'ຈັດການການຈອງ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      actionButton(
                        text: 'Check-in',
                        icon: Icons.login,
                        color: Colors.blue,
                        onPressed: status == 'checked_in' ||
                                status == 'cancelled' ||
                                paymentStatus != 'paid'
                            ? null
                            : () {
                                Navigator.pop(context);
                                checkIn(id);
                              },
                      ),
                      actionButton(
                        text: 'ຍົກເລີກ',
                        icon: Icons.delete_outline,
                        color: Colors.red,
                        outlined: true,
                        onPressed: status == 'cancelled'
                            ? null
                            : () {
                                Navigator.pop(context);
                                confirmAction(
                                  title: 'ຢືນຢັນຍົກເລີກ',
                                  message:
                                      'ຕ້ອງການຍົກເລີກການຈອງນີ້ແທ້ບໍ່?',
                                  color: Colors.red,
                                  onConfirm: () => cancelBooking(id),
                                );
                              },
                      ),
                    ],
                  ),
                  if (status == 'cancel_requested') ...[
                    const SizedBox(height: 18),
                    const Text(
                      'ຄຳຂໍຍົກເລີກຈາກລູກຄ້າ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        actionButton(
                          text: 'ອະນຸມັດຍົກເລີກ',
                          icon: Icons.check,
                          color: Colors.deepOrange,
                          onPressed: () {
                            Navigator.pop(context);
                            approveCancelRequest(id);
                          },
                        ),
                        actionButton(
                          text: 'ປະຕິເສດຄຳຂໍ',
                          icon: Icons.close,
                          color: Colors.grey.shade700,
                          outlined: true,
                          onPressed: () {
                            Navigator.pop(context);
                            rejectCancelRequest(id);
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ປິດ"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredBookings = getFilteredBookings();

    return Container(
      color: lightBg,
      child: Padding(
        padding: const EdgeInsets.all(34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "ຈັດການການຈອງ",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  onPressed: fetchBookings,
                  icon: const Icon(Icons.refresh),
                  label: const Text("ໂຫຼດຄືນ"),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                color: Colors.white,
                elevation: 3,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
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
                              enabled: filter != 'all' &&
                                  filter != 'cancel_requested',
                              decoration: InputDecoration(
                                labelText: filter == 'all'
                                    ? "ປະຫວັດທັງໝົດ"
                                    : filter == 'cancel_requested'
                                        ? "ຄຳຂໍຍົກເລີກທັງໝົດ"
                                        : "ກອງຕາມວັນທີ",
                                prefixIcon: const Icon(Icons.calendar_month),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onTap: filter == 'all' ||
                                      filter == 'cancel_requested'
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
                                  filterButton("ທັງໝົດ", "all"),
                                  filterButton("ກຳລັງໃຊ້ງານ", "active"),
                                  filterButton("ລໍຖ້າກວດສອບ", "pending"),
                                  filterButton("ຊຳລະແລ້ວ", "paid"),
                                  filterButton("ຈ່າຍບໍ່ຄົບ", "partial"),
                                  filterButton("ປະຕິເສດ", "rejected"),
                                  filterButton("ຂໍຍົກເລີກ", "cancel_requested"),
                                  filterButton("ຍົກເລີກ", "cancelled"),
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
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: primaryGreen,
                              ),
                            )
                          : filteredBookings.isEmpty
                              ? const Center(
                                  child: Text("ບໍ່ພົບຂໍ້ມູນການຈອງ"),
                                )
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
                                        headingRowColor:
                                            MaterialStateProperty.all(
                                          Colors.green.shade50,
                                        ),
                                        columns: const [
                                          DataColumn(label: Text("ລະຫັດຈອງ")),
                                          DataColumn(label: Text("ລູກຄ້າ")),
                                          DataColumn(label: Text("ສະໜາມ")),
                                          DataColumn(
                                            label: Text("ວັນທີ ແລະ ເວລາ"),
                                          ),
                                          DataColumn(label: Text("ຈຳນວນເງິນ")),
                                          DataColumn(label: Text("ສະຖານະ")),
                                          DataColumn(label: Text("ການຊຳລະ")),
                                          DataColumn(label: Text("ຈັດການ")),
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
                                                      Text(
                                                        formatDate(
                                                          booking[
                                                              'booking_date'],
                                                        ),
                                                      ),
                                                      Text(
                                                        "${formatTime(booking['start_time'])} - ${formatTime(booking['end_time'])}",
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
                                                  width: 130,
                                                  child: Text(
                                                    formatPrice(
                                                      booking['total_price'] ??
                                                          0,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: 150,
                                                  child: badge(
                                                    laoStatus(status),
                                                    statusColor(status),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: 150,
                                                  child: badge(
                                                    laoPayment(paymentStatus),
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
                                                    child: const Text(
                                                      "ຈັດການ",
                                                    ),
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
                              "ສະແດງ ${filteredBookings.length} ລາຍການ ຈາກທັງໝົດ ${bookings.length} ລາຍການ",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {},
                            child: const Text("ກ່ອນໜ້າ"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text("1"),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {},
                            child: const Text("ຖັດໄປ"),
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
      ),
    );
  }
}
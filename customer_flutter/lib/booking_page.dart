import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'payment_page.dart';

const Color primaryGreen = Color(0xFF16A34A);
const Color lightBg = Color(0xFFF4F8F1);

class BookingPage extends StatefulWidget {
  final String token;
  final Map customer;
  final Map field;

  const BookingPage({
    super.key,
    required this.token,
    required this.customer,
    required this.field,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? selectedDate;
  Map<String, dynamic>? selectedSlot;

  List services = [];
  List bookings = [];

  bool loading = true;

  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    selectedDate = now;

    loadData();
  }

  String get dateText {
    if (selectedDate == null) return 'ເລືອກວັນທີ';

    final y = selectedDate!.year.toString();
    final m = selectedDate!.month.toString().padLeft(2, '0');
    final d = selectedDate!.day.toString().padLeft(2, '0');

    return '$y-$m-$d';
  }

  String slotStart(Map slot) {
    return '${slot['hour_start'].toString().padLeft(2, '0')}:00:00';
  }

  String slotEnd(Map slot) {
    return '${slot['hour_end'].toString().padLeft(2, '0')}:00:00';
  }

  String slotLabel(Map slot) {
    final label = slot['label']?.toString();

    if (label != null && label.isNotEmpty) {
      return label;
    }

    return '${slot['hour_start']}:00 - ${slot['hour_end']}:00';
  }

  String shortTime(dynamic value) {
    if (value == null) return '';
    final text = value.toString();
    if (text.length >= 5) return text.substring(0, 5);
    return text;
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
      selectedSlot = null;
    });

    await fetchFieldServices();
    await fetchBookings();

    setState(() {
      loading = false;
    });
  }

  Future<void> fetchFieldServices() async {
    final fieldId = widget.field['id'];

    final response = await http.get(
      Uri.parse('http://localhost:4000/api/field-services?field_id=$fieldId'),
    );

    if (response.statusCode == 200) {
      services = jsonDecode(response.body);
    }
  }

  Future<void> fetchBookings() async {
    final fieldId = widget.field['id'];

    final response = await http.get(
      Uri.parse(
        'http://localhost:4000/api/bookings?date=$dateText&field_id=$fieldId',
      ),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      bookings = jsonDecode(response.body);
    }
  }

  bool isSlotBooked(Map slot) {
    final start = slotStart(slot);
    final end = slotEnd(slot);

    return bookings.any((booking) {
      if (booking['status'] == 'cancelled') return false;

      final bookingStart = booking['start_time'].toString();
      final bookingEnd = booking['end_time'].toString();

      return start.compareTo(bookingEnd) < 0 &&
          end.compareTo(bookingStart) > 0;
    });
  }

  Future<void> pickDate() async {
    final now = DateTime.now();

    final result = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      initialDate: selectedDate ?? now,
    );

    if (result != null) {
      setState(() {
        selectedDate = result;
        selectedSlot = null;
      });

      await loadData();
    }
  }

  void goToPaymentPage() {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ກະລຸນາເລືອກວັນທີຈອງ')),
      );
      return;
    }

    if (selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ກະລຸນາເລືອກເວລາ')),
      );
      return;
    }

    final slotForPayment = {
      'label': slotLabel(selectedSlot!),
      'start': slotStart(selectedSlot!),
      'end': slotEnd(selectedSlot!),
      'price': selectedSlot!['price_per_hour'],
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          token: widget.token,
          customer: widget.customer,
          field: widget.field,
          bookingDate: dateText,
          slot: slotForPayment,
          note: noteController.text,
        ),
      ),
    );
  }

  Widget fieldCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.sports_soccer,
                color: primaryGreen,
                size: 34,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.field['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.field['description'] ?? 'ສະໜາມຫຍ້າທຽມ',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget dateCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: pickDate,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, color: primaryGreen),
              const SizedBox(width: 12),
              const Text(
                'ວັນທີຈອງ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                dateText,
                style: const TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget slotChip(Map<String, dynamic> slot) {
    final booked = isSlotBooked(slot);
    final selected = selectedSlot == slot;

    return ChoiceChip(
      selected: selected,
      onSelected: booked
          ? null
          : (_) {
              setState(() {
                selectedSlot = slot;
              });
            },
      selectedColor: primaryGreen,
      disabledColor: Colors.grey.shade200,
      backgroundColor: Colors.white,
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              slotLabel(slot),
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : booked
                        ? Colors.grey
                        : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              booked
                  ? 'ຖືກຈອງແລ້ວ'
                  : '${slot['price_per_hour']} ກີບ',
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : booked
                        ? Colors.grey
                        : primaryGreen,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget summaryCard() {
    final price = selectedSlot == null
        ? '-'
        : '${selectedSlot!['price_per_hour']} ກີບ';

    final time = selectedSlot == null ? '-' : slotLabel(selectedSlot!);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ສະຫຼຸບການຈອງ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            summaryRow('ສະໜາມ', widget.field['name'] ?? '-'),
            summaryRow('ວັນທີ', dateText),
            summaryRow('ເວລາ', time),
            summaryRow('ລາຄາ', price),
          ],
        ),
      ),
    );
  }

  Widget summaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: const Text(
          'ຈອງສະໜາມ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            )
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                fieldCard(),
                const SizedBox(height: 18),

                const Text(
                  'ເລືອກວັນທີ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                dateCard(),

                const SizedBox(height: 22),

                const Text(
                  'ເລືອກເວລາ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                if (services.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('ບໍ່ພົບຊ່ວງເວລາຂອງສະໜາມນີ້'),
                    ),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: services.map((item) {
                      final slot = Map<String, dynamic>.from(item);
                      return slotChip(slot);
                    }).toList(),
                  ),

                const SizedBox(height: 24),

                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'ໝາຍເຫດ',
                    hintText: 'ຂຽນໝາຍເຫດເພີ່ມເຕີມ...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                summaryCard(),

                const SizedBox(height: 24),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: selectedSlot == null ? null : goToPaymentPage,
                    child: const Text(
                      'ດຳເນີນການຕໍ່',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
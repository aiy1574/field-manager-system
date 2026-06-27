import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'payment_page.dart';

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
  Map? selectedSlot;

  bool loadingSlots = true;
  List<Map<String, dynamic>> timeSlots = [];

  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchFieldServices();
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  String get dateText {
    if (selectedDate == null) return 'ເລືອກວັນທີຈອງ';

    final y = selectedDate!.year.toString();
    final m = selectedDate!.month.toString().padLeft(2, '0');
    final d = selectedDate!.day.toString().padLeft(2, '0');

    return '$y-$m-$d';
  }

  String timeText(dynamic value) {
    final number = int.tryParse(value.toString()) ?? 0;
    return number.toString().padLeft(2, '0');
  }

  int parsePrice(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return double.tryParse(value.toString())?.toInt() ?? 0;
  }

  String formatPrice(dynamic value) {
    final number = parsePrice(value);

    return number.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }

  Future<void> fetchFieldServices() async {
    setState(() {
      loadingSlots = true;
    });

    try {
      final fieldId = widget.field['id'];

      final response = await http
          .get(
            Uri.parse(
              'http://localhost:4000/api/field-services?field_id=$fieldId',
            ),
            headers: {
              'Authorization': 'Bearer ${widget.token}',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final loadedSlots = List<Map<String, dynamic>>.from(
          data.map((item) {
            final startHour = int.tryParse(item['hour_start'].toString()) ?? 0;
            final endHour = int.tryParse(item['hour_end'].toString()) ?? 0;

            final label = item['label']?.toString().isNotEmpty == true
                ? item['label'].toString()
                : '${timeText(startHour)}:00 - ${timeText(endHour)}:00';

            return {
              'id': item['id'],
              'field_service_id': item['id'],
              'label': label,
              'start': '${timeText(startHour)}:00:00',
              'end': '${timeText(endHour)}:00:00',
              'price': parsePrice(item['price_per_hour']),
            };
          }),
        );

        setState(() {
          timeSlots = loadedSlots;
          loadingSlots = false;
        });
      } else {
        setState(() {
          loadingSlots = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ໂຫຼດລາຄາສະໜາມບໍ່ໄດ້: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        loadingSlots = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ເຊື່ອມຕໍ່ Server ບໍ່ໄດ້: $e')),
      );
    }
  }

  Future<void> pickDate() async {
    final now = DateTime.now();

    final result = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      initialDate: now,
    );

    if (result != null) {
      setState(() {
        selectedDate = result;
        selectedSlot = null;
      });
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
        const SnackBar(content: Text('ກະລຸນາເລືອກເວລາຈອງ')),
      );
      return;
    }

    final price = parsePrice(selectedSlot!['price']);

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ລາຄາບໍ່ຖືກຕ້ອງ ກະລຸນາກວດຖານຂໍ້ມູນ'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          token: widget.token,
          customer: widget.customer,
          field: widget.field,
          bookingDate: dateText,
          slot: selectedSlot!,
          note: noteController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedLabel = selectedSlot == null
        ? 'ຍັງບໍ່ໄດ້ເລືອກເວລາ'
        : '${selectedSlot!['label']} | ${formatPrice(selectedSlot!['price'])} ກີບ';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F1),
      appBar: AppBar(
        title: const Text('ຈອງສະໜາມ'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(
                  Icons.sports_soccer,
                  color: Colors.white,
                ),
              ),
              title: Text(
                widget.field['name'] ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(widget.field['description'] ?? ''),
            ),
          ),
          const SizedBox(height: 20),

          OutlinedButton.icon(
            onPressed: pickDate,
            icon: const Icon(Icons.calendar_month),
            label: Text(dateText),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green.shade800,
              side: BorderSide(color: Colors.green.shade700),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'ເລືອກເວລາຈອງ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            selectedLabel,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          if (loadingSlots)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(color: Colors.green),
              ),
            )
          else if (timeSlots.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Text(
                'ສະໜາມນີ້ຍັງບໍ່ມີຕາຕະລາງລາຄາ',
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: timeSlots.map((slot) {
                final isSelected =
                    selectedSlot != null && selectedSlot!['id'] == slot['id'];

                return ChoiceChip(
                  selected: isSelected,
                  selectedColor: Colors.green,
                  backgroundColor: Colors.white,
                  labelPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        slot['label'].toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${formatPrice(slot['price'])} ກີບ',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  onSelected: (_) {
                    setState(() {
                      selectedSlot = slot;
                    });
                  },
                );
              }).toList(),
            ),

          const SizedBox(height: 25),

          TextField(
            controller: noteController,
            decoration: InputDecoration(
              labelText: 'ໝາຍເຫດ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: loadingSlots ? null : goToPaymentPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'ຖັດໄປ',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
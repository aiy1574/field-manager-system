import 'package:flutter/material.dart';

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

  final noteController = TextEditingController();

  final List<Map<String, String>> timeSlots = [
    {'label': '17:00 - 18:00', 'start': '17:00:00', 'end': '18:00:00'},
    {'label': '18:00 - 19:00', 'start': '18:00:00', 'end': '19:00:00'},
    {'label': '19:00 - 20:00', 'start': '19:00:00', 'end': '20:00:00'},
    {'label': '20:00 - 21:00', 'start': '20:00:00', 'end': '21:00:00'},
    {'label': '21:00 - 22:00', 'start': '21:00:00', 'end': '22:00:00'},
    {'label': '22:00 - 23:00', 'start': '22:00:00', 'end': '23:00:00'},
    {'label': '23:00 - 24:00', 'start': '23:00:00', 'end': '24:00:00'},
  ];

  String get dateText {
    if (selectedDate == null) return 'Select booking date';

    final y = selectedDate!.year.toString();
    final m = selectedDate!.month.toString().padLeft(2, '0');
    final d = selectedDate!.day.toString().padLeft(2, '0');

    return '$y-$m-$d';
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
        const SnackBar(content: Text('Please select booking date')),
      );
      return;
    }

    if (selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select time slot')),
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
        ? 'No time selected'
        : selectedSlot!['label'].toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Field'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(
                  Icons.sports_soccer,
                  color: Colors.white,
                ),
              ),
              title: Text(widget.field['name'] ?? ''),
              subtitle: Text(widget.field['description'] ?? ''),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: pickDate,
            icon: const Icon(Icons.calendar_month),
            label: Text(dateText),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Time Slot',
            style: TextStyle(
              fontSize: 18,
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: timeSlots.map((slot) {
              final isSelected = selectedSlot == slot;

              return ChoiceChip(
                label: Text(slot['label']!),
                selected: isSelected,
                selectedColor: Colors.green,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
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
            decoration: const InputDecoration(
              labelText: 'Note',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: goToPaymentPage,
              child: const Text(
                'Next',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
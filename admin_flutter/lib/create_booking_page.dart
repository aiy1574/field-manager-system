import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CreateBookingPage extends StatefulWidget {
  final String token;

  const CreateBookingPage({
    super.key,
    required this.token,
  });

  @override
  State<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends State<CreateBookingPage> {
  List fields = [];
  List bookings = [];

  int? selectedFieldId;
  Map<String, dynamic>? selectedSlot;

  final customerNameController = TextEditingController();
  final customerPhoneController = TextEditingController();
  final dateController = TextEditingController(text: "2026-05-26");
  final noteController = TextEditingController();

  final List<Map<String, dynamic>> timeSlots = [
    {
      'label': '17:00 - 18:00',
      'start': '17:00',
      'end': '18:00',
      'price': 500,
    },
    {
      'label': '18:00 - 19:00',
      'start': '18:00',
      'end': '19:00',
      'price': 700,
    },
    {
      'label': '19:00 - 20:00',
      'start': '19:00',
      'end': '20:00',
      'price': 700,
    },
    {
      'label': '20:00 - 21:00',
      'start': '20:00',
      'end': '21:00',
      'price': 800,
    },
    {
      'label': '21:00 - 22:00',
      'start': '21:00',
      'end': '22:00',
      'price': 800,
    },
  ];

  String normalizeTime(dynamic value) {
    if (value == null) return '';
    final text = value.toString();

    if (text.length >= 5) {
      return text.substring(0, 5);
    }

    return text;
  }

  Future<void> fetchFields() async {
    final response = await http.get(
      Uri.parse('http://localhost:4000/api/fields'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        fields = jsonDecode(response.body);

        if (fields.isNotEmpty) {
          selectedFieldId = fields[0]['id'];
        }
      });

      await refreshBookingsAfterChange();
    }
  }

  Future<void> fetchBookings() async {
    if (selectedFieldId == null) return;

    final response = await http.get(
      Uri.parse(
        'http://localhost:4000/api/bookings?date=${dateController.text}&field_id=$selectedFieldId',
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

  bool isSlotBooked(Map<String, dynamic> slot) {
    return bookings.any((booking) {
      final bookingStart = normalizeTime(booking['start_time']);
      final bookingEnd = normalizeTime(booking['end_time']);

      return bookingStart == slot['start'] &&
          bookingEnd == slot['end'] &&
          booking['status'] != 'cancelled';
    });
  }

  void selectFirstAvailableSlot() {
    for (final slot in timeSlots) {
      if (!isSlotBooked(slot)) {
        setState(() {
          selectedSlot = slot;
        });
        return;
      }
    }

    setState(() {
      selectedSlot = null;
    });
  }

  Future<void> refreshBookingsAfterChange() async {
    await fetchBookings();
    selectFirstAvailableSlot();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Available time updated"),
      ),
    );
  }

  Future<int?> createCustomer() async {
    final response = await http.post(
      Uri.parse('http://localhost:4000/api/customers'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'full_name': customerNameController.text,
        'phone': customerPhoneController.text,
      }),
    );

    print(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'];
    }

    return null;
  }

  Future<void> createBooking() async {
    if (selectedFieldId == null || selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select field and available time slot"),
        ),
      );
      return;
    }

    if (isSlotBooked(selectedSlot!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This time slot is already booked"),
        ),
      );
      return;
    }

    final customerId = await createCustomer();

    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Create customer failed"),
        ),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://localhost:4000/api/bookings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'field_id': selectedFieldId,
        'customer_id': customerId,
        'booking_date': dateController.text,
        'start_time': selectedSlot!['start'],
        'end_time': selectedSlot!['end'],
        'total_price': selectedSlot!['price'],
        'note': noteController.text,
      }),
    );

    print(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Booking created successfully"),
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.body),
        ),
      );

      await refreshBookingsAfterChange();
    }
  }

  @override
  void initState() {
    super.initState();
    fetchFields();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Booking"),
        actions: [
          IconButton(
            onPressed: refreshBookingsAfterChange,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            DropdownButtonFormField<int>(
              value: selectedFieldId,
              decoration: const InputDecoration(
                labelText: "Field",
              ),
              items: fields.map<DropdownMenuItem<int>>((field) {
                return DropdownMenuItem<int>(
                  value: field['id'],
                  child: Text(field['name']),
                );
              }).toList(),
              onChanged: (value) async {
                setState(() {
                  selectedFieldId = value;
                  selectedSlot = null;
                });

                await refreshBookingsAfterChange();
              },
            ),

            const SizedBox(height: 15),

            TextField(
              controller: customerNameController,
              decoration: const InputDecoration(
                labelText: "Customer Name",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: customerPhoneController,
              decoration: const InputDecoration(
                labelText: "Customer Phone",
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: dateController,
              readOnly: true,
              decoration: const InputDecoration(
              labelText: "Booking Date",
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
                  final formatted =
                      "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";

                  setState(() {
                    dateController.text = formatted;
                  });

                refreshBookingsAfterChange();
              }
            },
          ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: refreshBookingsAfterChange,
              child: const Text("Check Available Time"),
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<Map<String, dynamic>>(
              value: selectedSlot,
              decoration: const InputDecoration(
                labelText: "Time Slot",
              ),
              items: timeSlots.map((slot) {
                final booked = isSlotBooked(slot);

                return DropdownMenuItem<Map<String, dynamic>>(
                  value: booked ? null : slot,
                  enabled: !booked,
                  child: Text(
                    booked
                        ? '❌ ${slot['label']} - Booked'
                        : '✅ ${slot['label']} - ${slot['price']} Kip',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedSlot = value;
                });
              },
            ),

            const SizedBox(height: 15),

            Text(
              selectedSlot == null
                  ? "Price: -"
                  : "Price: ${selectedSlot!['price']} Kip",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: "Note",
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: selectedSlot == null ? null : createBooking,
              child: const Text("Create Booking"),
            ),
          ],
        ),
      ),
    );
  }
}
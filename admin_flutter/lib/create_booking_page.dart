import 'dart:convert';

import 'theme.dart';
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
  List fieldServices = [];

  int? selectedFieldId;
  Map<String, dynamic>? selectedSlot;

  bool loading = false;

  final customerNameController = TextEditingController();
  final customerPhoneController = TextEditingController();
  final dateController = TextEditingController();
  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    dateController.text =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    fetchFields();
  }

  String normalizeTime(dynamic value) {
    if (value == null) return '';
    final text = value.toString();

    if (text.length >= 5) {
      return text.substring(0, 5);
    }

    return text;
  }

  String slotStart(Map<String, dynamic> slot) {
    return "${slot['hour_start'].toString().padLeft(2, '0')}:00";
  }

  String slotEnd(Map<String, dynamic> slot) {
    return "${slot['hour_end'].toString().padLeft(2, '0')}:00";
  }

  String slotLabel(Map<String, dynamic> slot) {
    final label = slot['label']?.toString() ?? '';
    final start = slotStart(slot);
    final end = slotEnd(slot);
    final price = slot['price_per_hour']?.toString() ?? '0';

    if (label.isNotEmpty) {
      return "$label | $start - $end | $price Kip";
    }

    return "$start - $end | $price Kip";
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

  Future<void> fetchFieldServices() async {
    if (selectedFieldId == null) return;

    final response = await http.get(
      Uri.parse(
        'http://localhost:4000/api/field-services?field_id=$selectedFieldId',
      ),
    );

    if (response.statusCode == 200) {
      setState(() {
        fieldServices = jsonDecode(response.body);
      });
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

      return bookingStart == slotStart(slot) &&
          bookingEnd == slotEnd(slot) &&
          booking['status'] != 'cancelled';
    });
  }

  void selectFirstAvailableSlot() {
    for (final item in fieldServices) {
      final slot = Map<String, dynamic>.from(item);

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
    setState(() {
      loading = true;
      selectedSlot = null;
    });

    await fetchFieldServices();
    await fetchBookings();
    selectFirstAvailableSlot();

    setState(() {
      loading = false;
    });
  }

  Future<int?> createCustomer() async {
    final response = await http.post(
      Uri.parse('http://localhost:4000/api/customers'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'full_name': customerNameController.text.trim(),
        'phone': customerPhoneController.text.trim(),
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'];
    }

    return null;
  }

  Future<void> createBooking() async {
    if (customerNameController.text.trim().isEmpty ||
        customerPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter customer name and phone"),
        ),
      );
      return;
    }

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
      await refreshBookingsAfterChange();
      return;
    }

    setState(() {
      loading = true;
    });

    final customerId = await createCustomer();

    if (customerId == null) {
      setState(() {
        loading = false;
      });

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
        'start_time': slotStart(selectedSlot!),
        'end_time': slotEnd(selectedSlot!),
        'total_price': selectedSlot!['price_per_hour'],
        'note': noteController.text.trim(),
      }),
    );

    setState(() {
      loading = false;
    });

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

  Widget fieldDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedFieldId,
      decoration: const InputDecoration(
        labelText: "Field",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.stadium),
      ),
      items: fields.map<DropdownMenuItem<int>>((field) {
        return DropdownMenuItem<int>(
          value: field['id'],
          child: Text(field['name'] ?? '-'),
        );
      }).toList(),
      onChanged: (value) async {
        setState(() {
          selectedFieldId = value;
          selectedSlot = null;
        });

        await refreshBookingsAfterChange();
      },
    );
  }

  Widget timeSlotDropdown() {
    return DropdownButtonFormField<Map<String, dynamic>>(
      value: selectedSlot,
      decoration: const InputDecoration(
        labelText: "Time Slot",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.access_time),
      ),
      items: fieldServices.map<DropdownMenuItem<Map<String, dynamic>>>((item) {
        final slot = Map<String, dynamic>.from(item);
        final booked = isSlotBooked(slot);

        return DropdownMenuItem<Map<String, dynamic>>(
          value: booked ? null : slot,
          enabled: !booked,
          child: Text(
            booked ? "❌ ${slotLabel(slot)} - Booked" : "✅ ${slotLabel(slot)}",
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          selectedSlot = value;
        });
      },
    );
  }

  Widget priceCard() {
    final price = selectedSlot == null
        ? "-"
        : "${selectedSlot!['price_per_hour']} Kip";

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.green.shade50,
              child: Icon(
                Icons.payments,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              "Total Price:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              price,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget bookedListCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Booked Time Today",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            if (bookings.isEmpty)
              const Text("No booking on this date")
            else
              ...bookings.map((booking) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.event_busy),
                  title: Text(
                    "${normalizeTime(booking['start_time'])} - ${normalizeTime(booking['end_time'])}",
                  ),
                  subtitle: Text(
                    "${booking['customer_name'] ?? '-'} | ${booking['status'] ?? '-'}",
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Create Booking",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: loading ? null : refreshBookingsAfterChange,
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh"),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 900;

                            final form = Column(
                              children: [
                                fieldDropdown(),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: customerNameController,
                                  decoration: const InputDecoration(
                                    labelText: "Customer Name",
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: customerPhoneController,
                                  decoration: const InputDecoration(
                                    labelText: "Customer Phone",
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.phone),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: dateController,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: "Booking Date",
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.calendar_month),
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

                                      await refreshBookingsAfterChange();
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                timeSlotDropdown(),
                                const SizedBox(height: 16),
                                priceCard(),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: noteController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: "Note",
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.note),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton.icon(
                                    onPressed: selectedSlot == null || loading
                                        ? null
                                        : createBooking,
                                    icon: const Icon(Icons.add),
                                    label: const Text("Create Booking"),
                                  ),
                                ),
                              ],
                            );

                            if (!isWide) {
                              return Column(
                                children: [
                                  form,
                                  const SizedBox(height: 20),
                                  bookedListCard(),
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: form,
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: bookedListCard(),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
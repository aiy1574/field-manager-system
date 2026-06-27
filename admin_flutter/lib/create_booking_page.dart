import 'dart:async';
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
  List fieldServices = [];

  int? selectedFieldId;
  int? selectedSlotId;
  Map<String, dynamic>? selectedSlot;

  bool loading = false;
  Timer? autoRefreshTimer;

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

    autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (!mounted || loading) return;
        autoRefreshBookingsOnly();
      },
    );
  }

  @override
  void dispose() {
    autoRefreshTimer?.cancel();

    customerNameController.dispose();
    customerPhoneController.dispose();
    dateController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
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

  String slotStartForDb(Map<String, dynamic> slot) {
    return "${slot['hour_start'].toString().padLeft(2, '0')}:00:00";
  }

  String slotEndForDb(Map<String, dynamic> slot) {
    return "${slot['hour_end'].toString().padLeft(2, '0')}:00:00";
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

  String slotLabel(Map<String, dynamic> slot) {
    final label = slot['label']?.toString() ?? '';
    final start = slotStart(slot);
    final end = slotEnd(slot);
    final price = formatPrice(slot['price_per_hour']);

    if (label.isNotEmpty) {
      return "$label | $price ກີບ";
    }

    return "$start - $end | $price ກີບ";
  }

  Future<void> fetchFields() async {
    setState(() {
      loading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:4000/api/fields'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          fields = data;

          if (fields.isNotEmpty) {
            selectedFieldId = int.tryParse(fields[0]['id'].toString());
          } else {
            selectedFieldId = null;
          }
        });

        await refreshBookingsAfterChange();
      } else {
        setState(() {
          loading = false;
        });

        showMessage('ໂຫຼດຂໍ້ມູນສະໜາມບໍ່ສຳເລັດ', error: true);
      }
    } catch (e) {
      setState(() {
        loading = false;
      });

      showMessage('ເຊື່ອມຕໍ່ Server ບໍ່ໄດ້: $e', error: true);
    }
  }

  Future<void> fetchFieldServices() async {
    if (selectedFieldId == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          'http://localhost:4000/api/field-services?field_id=$selectedFieldId',
        ),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        setState(() {
          fieldServices = jsonDecode(response.body);
        });
      } else {
        showMessage('ໂຫຼດເວລາ ແລະ ລາຄາບໍ່ສຳເລັດ', error: true);
      }
    } catch (e) {
      showMessage('ໂຫຼດເວລາສະໜາມຜິດພາດ: $e', error: true);
    }
  }

  Future<void> fetchBookings() async {
    if (selectedFieldId == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          'http://localhost:4000/api/bookings?date=${dateController.text}&field_id=$selectedFieldId',
        ),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        setState(() {
          bookings = jsonDecode(response.body);
        });
      } else {
        showMessage('ໂຫຼດຂໍ້ມູນການຈອງບໍ່ສຳເລັດ', error: true);
      }
    } catch (e) {
      showMessage('ໂຫຼດການຈອງຜິດພາດ: $e', error: true);
    }
  }

  Future<void> autoRefreshBookingsOnly() async {
    if (selectedFieldId == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          'http://localhost:4000/api/bookings?date=${dateController.text}&field_id=$selectedFieldId',
        ),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          bookings = jsonDecode(response.body);
        });
      }
    } catch (_) {
      // ບໍ່ຕ້ອງ show error ທຸກ 5 ວິນາທີ
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
          selectedSlotId = int.tryParse(slot['id'].toString());
        });
        return;
      }
    }

    setState(() {
      selectedSlot = null;
      selectedSlotId = null;
    });
  }

  Future<void> refreshBookingsAfterChange() async {
    setState(() {
      loading = true;
      selectedSlot = null;
      selectedSlotId = null;
    });

    await fetchFieldServices();
    await fetchBookings();
    selectFirstAvailableSlot();

    setState(() {
      loading = false;
    });
  }

  Future<int?> createCustomer() async {
    try {
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

      showMessage(response.body, error: true);
      return null;
    } catch (e) {
      showMessage('ສ້າງລູກຄ້າຜິດພາດ: $e', error: true);
      return null;
    }
  }

  Future<void> createBooking() async {
    if (customerNameController.text.trim().isEmpty ||
        customerPhoneController.text.trim().isEmpty) {
      showMessage('ກະລຸນາປ້ອນຊື່ ແລະ ເບີໂທລູກຄ້າ', error: true);
      return;
    }

    if (selectedFieldId == null || selectedSlot == null) {
      showMessage('ກະລຸນາເລືອກສະໜາມ ແລະ ເວລາວ່າງ', error: true);
      return;
    }

    if (isSlotBooked(selectedSlot!)) {
      showMessage('ເວລານີ້ຖືກຈອງແລ້ວ', error: true);
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
      return;
    }

    try {
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
          'start_time': slotStartForDb(selectedSlot!),
          'end_time': slotEndForDb(selectedSlot!),
          'total_price': selectedSlot!['price_per_hour'],
          'note': noteController.text.trim(),
          'slip_image': null,
        }),
      );

      setState(() {
        loading = false;
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        showMessage('ສ້າງການຈອງສຳເລັດ');

        customerNameController.clear();
        customerPhoneController.clear();
        noteController.clear();

        await refreshBookingsAfterChange();
      } else if (response.statusCode == 409) {
        showMessage('ເວລານີ້ຖືກຈອງແລ້ວ', error: true);
        await refreshBookingsAfterChange();
      } else {
        showMessage(response.body, error: true);
        await refreshBookingsAfterChange();
      }
    } catch (e) {
      setState(() {
        loading = false;
      });

      showMessage('ສ້າງການຈອງຜິດພາດ: $e', error: true);
    }
  }

  Widget fieldDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedFieldId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'ສະໜາມ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.stadium),
      ),
      items: fields.map<DropdownMenuItem<int>>((field) {
        return DropdownMenuItem<int>(
          value: int.tryParse(field['id'].toString()),
          child: Text(
            field['name'] ?? '-',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) async {
        setState(() {
          selectedFieldId = value;
          selectedSlot = null;
          selectedSlotId = null;
        });

        await refreshBookingsAfterChange();
      },
    );
  }

  Widget timeSlotDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedSlotId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'ເວລາຈອງ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.access_time),
      ),
      items: fieldServices.map<DropdownMenuItem<int>>((item) {
        final slot = Map<String, dynamic>.from(item);
        final booked = isSlotBooked(slot);
        final slotId = int.tryParse(slot['id'].toString());

        return DropdownMenuItem<int>(
          value: slotId,
          enabled: !booked,
          child: Text(
            booked
                ? '❌ ${slotLabel(slot)} - ຖືກຈອງແລ້ວ'
                : '✅ ${slotLabel(slot)}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;

        Map<String, dynamic>? foundSlot;

        for (final item in fieldServices) {
          final itemId = int.tryParse(item['id'].toString());

          if (itemId == value) {
            foundSlot = Map<String, dynamic>.from(item);
            break;
          }
        }

        if (foundSlot == null) return;

        setState(() {
          selectedSlotId = value;
          selectedSlot = foundSlot;
        });
      },
    );
  }

  Widget priceCard() {
    final price = selectedSlot == null
        ? '-'
        : '${formatPrice(selectedSlot!['price_per_hour'])} ກີບ';

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
              'ລາຄາລວມ:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                price,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
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
              'ເວລາທີ່ຖືກຈອງໃນວັນນີ້',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            if (bookings.isEmpty)
              const Text('ຍັງບໍ່ມີການຈອງໃນວັນນີ້')
            else
              ...bookings.map((booking) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.event_busy),
                  title: Text(
                    '${normalizeTime(booking['start_time'])} - ${normalizeTime(booking['end_time'])}',
                  ),
                  subtitle: Text(
                    '${booking['customer_name'] ?? '-'} | ${booking['status'] ?? '-'}',
                  ),
                );
              }),
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
                  'ຈອງເດີ່ນໜ້າຮ້ານ',
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
                label: const Text('ໂຫຼດຄືນ'),
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
                                  decoration: InputDecoration(
                                    labelText: 'ຊື່ລູກຄ້າ',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.person),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: customerPhoneController,
                                  decoration: InputDecoration(
                                    labelText: 'ເບີໂທລູກຄ້າ',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.phone),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: dateController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'ວັນທີຈອງ',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon:
                                        const Icon(Icons.calendar_month),
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
                                          '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';

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
                                  decoration: InputDecoration(
                                    labelText: 'ໝາຍເຫດ',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.note),
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
                                    label: const Text(
                                      'ສ້າງການຈອງ',
                                      style: TextStyle(fontSize: 17),
                                    ),
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
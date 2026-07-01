import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const Color primaryGreen = Color(0xFF16A34A);
const Color darkGreen = Color(0xFF0F8A43);
const Color lightBg = Color(0xFFF4F8F1);
const Color softCard = Color(0xFFFFFFFF);

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
  final String baseUrl = 'http://localhost:4000/api';

  List fields = [];
  List bookings = [];
  List services = [];
  List<Map<String, dynamic>> slots = [];

  int? selectedFieldId;
  Map<String, dynamic>? selectedSlot;

  bool loading = false;
  bool creating = false;

  final customerNameController = TextEditingController();
  final customerPhoneController = TextEditingController();
  final dateController = TextEditingController();
  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    dateController.text = formatDateOnly(now);

    fetchInitialData();
  }

  @override
  void dispose() {
    customerNameController.dispose();
    customerPhoneController.dispose();
    dateController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Map<String, String> get authHeaders {
    return {
      'Authorization': 'Bearer ${widget.token}',
    };
  }

  Map<String, String> get jsonHeaders {
    return {
      'Authorization': 'Bearer ${widget.token}',
      'Content-Type': 'application/json',
    };
  }

  String formatDateOnly(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String normalizeTime(dynamic value) {
    if (value == null) return '';

    final text = value.toString();

    if (text.length >= 5) {
      return text.substring(0, 5);
    }

    return text;
  }

  int timeToHour(dynamic value) {
    final text = normalizeTime(value);

    if (text.isEmpty) return 0;

    final parts = text.split(':');

    return int.tryParse(parts.first) ?? 0;
  }

  String hourText(int hour) {
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  String money(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '0') ?? 0;
    final intNumber = number.round();

    return intNumber.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  String getFieldName() {
    if (selectedFieldId == null) return '-';

    final found = fields.where((f) => f['id'] == selectedFieldId).toList();

    if (found.isEmpty) return '-';

    return found.first['name']?.toString() ?? '-';
  }

  String getMessage(String body, String fallback) {
    try {
      final data = jsonDecode(body);
      return data['message']?.toString() ?? fallback;
    } catch (_) {
      return body.isEmpty ? fallback : body;
    }
  }

  void showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.red : primaryGreen,
        content: Text(message),
      ),
    );
  }

  Future<void> fetchInitialData() async {
    setState(() {
      loading = true;
    });

    await fetchFields();

    setState(() {
      loading = false;
    });
  }

  Future<void> fetchFields() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fields'),
        headers: authHeaders,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          fields = data is List ? data : [];

          if (fields.isNotEmpty && selectedFieldId == null) {
            selectedFieldId = fields.first['id'];
          }
        });

        await refreshByFieldOrDate();
      } else {
        showMessage(
          getMessage(response.body, 'ໂຫຼດຂໍ້ມູນເດີ່ນບໍ່ສຳເລັດ'),
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showMessage('ເຊື່ອມຕໍ່ server ບໍ່ໄດ້: $e', isError: true);
    }
  }

  Future<void> refreshByFieldOrDate() async {
    if (selectedFieldId == null) return;

    setState(() {
      loading = true;
      selectedSlot = null;
    });

    await fetchFieldServices();
    await fetchBookings();
    buildSlotsFromServices();
    selectFirstAvailableSlot();

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  Future<void> fetchFieldServices() async {
    if (selectedFieldId == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/field-services?field_id=$selectedFieldId'),
        headers: authHeaders,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          services = data is List ? data : [];
        });
      } else {
        setState(() {
          services = [];
        });

        showMessage(
          getMessage(response.body, 'ໂຫຼດລາຄາເດີ່ນບໍ່ສຳເລັດ'),
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        services = [];
      });

      showMessage('ໂຫຼດ time slot ບໍ່ໄດ້: $e', isError: true);
    }
  }

  Future<void> fetchBookings() async {
    if (selectedFieldId == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/bookings?date=${dateController.text}&field_id=$selectedFieldId',
        ),
        headers: authHeaders,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          bookings = data is List ? data : [];
        });
      } else {
        setState(() {
          bookings = [];
        });

        showMessage(
          getMessage(response.body, 'ໂຫຼດການຈອງບໍ່ສຳເລັດ'),
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        bookings = [];
      });

      showMessage('ໂຫຼດການຈອງບໍ່ໄດ້: $e', isError: true);
    }
  }

  double servicePrice(Map service) {
    final value = service['price'] ??
        service['price_per_hour'] ??
        service['total_price'] ??
        service['amount'] ??
        0;

    return double.tryParse(value.toString()) ?? 0;
  }

  int serviceStartHour(Map service) {
    if (service.containsKey('hour_start')) {
      return int.tryParse(service['hour_start'].toString()) ?? 0;
    }

    return timeToHour(service['start_time']);
  }

  int serviceEndHour(Map service) {
    if (service.containsKey('hour_end')) {
      return int.tryParse(service['hour_end'].toString()) ?? 0;
    }

    return timeToHour(service['end_time']);
  }

  void buildSlotsFromServices() {
    final List<Map<String, dynamic>> generated = [];

    for (final raw in services) {
      final service = Map<String, dynamic>.from(raw);

      final startHour = serviceStartHour(service);
      final endHour = serviceEndHour(service);
      final price = servicePrice(service);

      if (startHour <= 0 || endHour <= 0 || endHour <= startHour) {
        continue;
      }

      for (int hour = startHour; hour < endHour; hour++) {
        final slot = {
          'start_time': hourText(hour),
          'end_time': hourText(hour + 1),
          'price': price,
        };

        generated.add(slot);
      }
    }

    generated.sort((a, b) {
      return a['start_time'].toString().compareTo(b['start_time'].toString());
    });

    setState(() {
      slots = generated;
    });
  }

  bool isSlotBooked(Map<String, dynamic> slot) {
    final slotStart = normalizeTime(slot['start_time']);
    final slotEnd = normalizeTime(slot['end_time']);

    return bookings.any((booking) {
      final status = booking['status']?.toString() ?? '';
      final bookingStart = normalizeTime(booking['start_time']);
      final bookingEnd = normalizeTime(booking['end_time']);

      if (status == 'cancelled') return false;

      return bookingStart == slotStart && bookingEnd == slotEnd;
    });
  }

  void selectFirstAvailableSlot() {
    for (final slot in slots) {
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

  bool isSelectedSlot(Map<String, dynamic> slot) {
    if (selectedSlot == null) return false;

    return selectedSlot!['start_time'] == slot['start_time'] &&
        selectedSlot!['end_time'] == slot['end_time'];
  }

  Future<int?> findCustomerByPhone(String phone) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers'),
        headers: authHeaders,
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);

      if (data is! List) return null;

      for (final customer in data) {
        final customerPhone = customer['phone']?.toString() ?? '';

        if (customerPhone == phone) {
          return int.tryParse(customer['id'].toString());
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<int?> createOrFindCustomer() async {
    final name = customerNameController.text.trim();
    final phone = customerPhoneController.text.trim();

    final existingId = await findCustomerByPhone(phone);

    if (existingId != null) return existingId;

    final response = await http.post(
      Uri.parse('$baseUrl/customers'),
      headers: jsonHeaders,
      body: jsonEncode({
        'full_name': name,
        'phone': phone,
        'password': '123456',
        'note': 'Walk-in booking from admin',
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return int.tryParse(data['id'].toString());
    }

    showMessage(
      getMessage(response.body, 'ສ້າງລູກຄ້າບໍ່ສຳເລັດ'),
      isError: true,
    );

    return null;
  }

  Future<void> createBooking() async {
    final name = customerNameController.text.trim();
    final phone = customerPhoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      showMessage('ກະລຸນາປ້ອນຊື່ລູກຄ້າ ແລະ ເບີໂທ', isError: true);
      return;
    }

    if (selectedFieldId == null) {
      showMessage('ກະລຸນາເລືອກເດີ່ນ', isError: true);
      return;
    }

    if (selectedSlot == null) {
      showMessage('ກະລຸນາເລືອກເວລາທີ່ວ່າງ', isError: true);
      return;
    }

    if (isSlotBooked(selectedSlot!)) {
      showMessage('ເວລານີ້ຖືກຈອງແລ້ວ', isError: true);
      await refreshByFieldOrDate();
      return;
    }

    setState(() {
      creating = true;
    });

    final customerId = await createOrFindCustomer();

    if (customerId == null) {
      if (!mounted) return;

      setState(() {
        creating = false;
      });

      return;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: jsonHeaders,
      body: jsonEncode({
        'field_id': selectedFieldId,
        'customer_id': customerId,
        'booking_date': dateController.text,
        'start_time': selectedSlot!['start_time'],
        'end_time': selectedSlot!['end_time'],
        'total_price': selectedSlot!['price'],
        'note': noteController.text.trim(),
      }),
    );

    if (!mounted) return;

    setState(() {
      creating = false;
    });

    if (response.statusCode == 201 || response.statusCode == 200) {
      showMessage('ສ້າງການຈອງສຳເລັດ');

      customerNameController.clear();
      customerPhoneController.clear();
      noteController.clear();

      await refreshByFieldOrDate();
    } else {
      showMessage(
        getMessage(response.body, 'ສ້າງການຈອງບໍ່ສຳເລັດ'),
        isError: true,
      );

      await refreshByFieldOrDate();
    }
  }

  Future<void> pickDate() async {
    final current = DateTime.tryParse(dateController.text) ?? DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      dateController.text = formatDateOnly(pickedDate);
      await refreshByFieldOrDate();
    }
  }

  Widget headerSection() {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.add_circle_outline,
            color: darkGreen,
            size: 30,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ຈອງເດີ່ນໜ້າຮ້ານ',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'ສ້າງການຈອງໃຫ້ລູກຄ້າ Walk-in',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          onPressed: loading ? null : refreshByFieldOrDate,
          icon: const Icon(Icons.refresh),
          label: const Text('ໂຫຼດຄືນ'),
        ),
      ],
    );
  }

  Widget fieldSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: softCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: DropdownButtonFormField<int>(
        value: selectedFieldId,
        decoration: InputDecoration(
          labelText: 'ເລືອກເດີ່ນ',
          prefixIcon: const Icon(Icons.stadium),
          filled: true,
          fillColor: lightBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        items: fields.map<DropdownMenuItem<int>>((field) {
          return DropdownMenuItem<int>(
            value: field['id'],
            child: Text(field['name']?.toString() ?? '-'),
          );
        }).toList(),
        onChanged: (value) async {
          setState(() {
            selectedFieldId = value;
            selectedSlot = null;
          });

          await refreshByFieldOrDate();
        },
      ),
    );
  }

  Widget customerForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: softCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: customerNameController,
            decoration: InputDecoration(
              labelText: 'ຊື່ລູກຄ້າ',
              prefixIcon: const Icon(Icons.person),
              filled: true,
              fillColor: lightBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: customerPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'ເບີໂທລູກຄ້າ',
              prefixIcon: const Icon(Icons.phone),
              filled: true,
              fillColor: lightBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: dateController,
            readOnly: true,
            onTap: pickDate,
            decoration: InputDecoration(
              labelText: 'ວັນທີຈອງ',
              prefixIcon: const Icon(Icons.calendar_month),
              suffixIcon: const Icon(Icons.arrow_drop_down),
              filled: true,
              fillColor: lightBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: noteController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'ໝາຍເຫດ',
              prefixIcon: const Icon(Icons.note),
              filled: true,
              fillColor: lightBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget priceCard() {
    final price =
        selectedSlot == null ? '-' : '${money(selectedSlot!['price'])} ກີບ';
    final time = selectedSlot == null
        ? 'ຍັງບໍ່ເລືອກເວລາ'
        : '${selectedSlot!['start_time']} - ${selectedSlot!['end_time']}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.green.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.shade100,
            child: const Icon(
              Icons.payments,
              color: darkGreen,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ລາຄາລວມ',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget slotCard(Map<String, dynamic> slot) {
    final booked = isSlotBooked(slot);
    final selected = isSelectedSlot(slot);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: booked
          ? null
          : () {
              setState(() {
                selectedSlot = slot;
              });
            },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: booked
              ? Colors.grey.shade100
              : selected
                  ? Colors.green.shade50
                  : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: booked
                ? Colors.grey.shade300
                : selected
                    ? primaryGreen
                    : Colors.green.shade100,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: booked
                  ? Colors.grey.shade300
                  : selected
                      ? primaryGreen
                      : Colors.green.shade100,
              child: Icon(
                booked
                    ? Icons.lock
                    : selected
                        ? Icons.check
                        : Icons.access_time,
                size: 20,
                color: booked
                    ? Colors.grey.shade700
                    : selected
                        ? Colors.white
                        : darkGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${slot['start_time']} - ${slot['end_time']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: booked ? Colors.grey : Colors.black87,
                ),
              ),
            ),
            Text(
              booked ? 'ຖືກຈອງແລ້ວ' : '${money(slot['price'])} ກີບ',
              style: TextStyle(
                color: booked ? Colors.red : primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget timeSlotSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: softCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: primaryGreen),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ເລືອກເວລາຈອງ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                getFieldName(),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (slots.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'ບໍ່ພົບ Time Slot ຂອງເດີ່ນນີ້. ໃຫ້ໄປຕັ້ງລາຄາທີ່ໜ້າຈັດການເດີ່ນກ່ອນ.',
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Column(
              children: slots.map((slot) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: slotCard(slot),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget bookedListCard() {
    final activeBookings = bookings.where((booking) {
      return booking['status']?.toString() != 'cancelled';
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: softCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.event_busy, color: primaryGreen),
              SizedBox(width: 8),
              Text(
                'ເວລາທີ່ຖືກຈອງແລ້ວ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (activeBookings.isEmpty)
            Text(
              'ວັນນີ້ຍັງບໍ່ມີການຈອງ',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            )
          else
            ...activeBookings.map((booking) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_busy,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${normalizeTime(booking['start_time'])} - ${normalizeTime(booking['end_time'])}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      booking['customer_name']?.toString() ?? '-',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget formColumn() {
    return Column(
      children: [
        fieldSection(),
        const SizedBox(height: 16),
        customerForm(),
        const SizedBox(height: 16),
        priceCard(),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: creating || loading || selectedSlot == null
                ? null
                : createBooking,
            icon: creating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.add),
            label: Text(
              creating ? 'ກຳລັງບັນທຶກ...' : 'ສ້າງການຈອງ',
            ),
          ),
        ),
      ],
    );
  }

  Widget content() {
    if (loading && fields.isEmpty) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(
            color: primaryGreen,
          ),
        ),
      );
    }

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1050;

          if (!isWide) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  formColumn(),
                  const SizedBox(height: 18),
                  timeSlotSection(),
                  const SizedBox(height: 18),
                  bookedListCard(),
                ],
              ),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  child: formColumn(),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      timeSlotSection(),
                      const SizedBox(height: 18),
                      bookedListCard(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: lightBg,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headerSection(),
          const SizedBox(height: 22),
          content(),
        ],
      ),
    );
  }
}

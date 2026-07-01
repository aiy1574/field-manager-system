import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const Color primaryGreen = Color(0xFF16A34A);
const Color darkGreen = Color(0xFF0F8A43);
const Color lightBg = Color(0xFFF4F8F1);
const Color softCard = Color(0xFFFFFFFF);

class CheckinPage extends StatefulWidget {
  final String token;

  const CheckinPage({
    super.key,
    required this.token,
  });

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  final String baseUrl = 'http://localhost:4000/api';

  List bookings = [];
  bool loading = true;
  bool checkingIn = false;

  String filter = 'all';

  final dateController = TextEditingController();
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    dateController.text = formatDateOnly(now);

    fetchBookings();
  }

  @override
  void dispose() {
    dateController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Map<String, String> get authHeaders {
    return {
      'Authorization': 'Bearer ${widget.token}',
    };
  }

  String formatDateOnly(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String normalizeTime(dynamic value) {
    if (value == null) return '-';

    final text = value.toString();

    if (text.length >= 5) {
      return text.substring(0, 5);
    }

    return text;
  }

  String normalizeDate(dynamic value) {
    if (value == null) return '-';

    final text = value.toString();

    if (text.length >= 10) {
      return text.substring(0, 10);
    }

    return text;
  }

  String money(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '0') ?? 0;
    final intNumber = number.round();

    return intNumber.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
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

  Future<void> fetchBookings() async {
    setState(() {
      loading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings?date=${dateController.text}'),
        headers: authHeaders,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          bookings = data is List ? data : [];
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });

        showMessage(
          getMessage(response.body, 'ໂຫຼດຂໍ້ມູນບໍ່ສຳເລັດ'),
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      showMessage('ເຊື່ອມຕໍ່ server ບໍ່ໄດ້: $e', isError: true);
    }
  }

  Future<void> checkIn(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFEAF7EE),
                child: Icon(Icons.login, color: primaryGreen),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text('ຢືນຢັນແຈ້ງເຂົ້າເດີ່ນ'),
              ),
            ],
          ),
          content: const Text(
            'ຕ້ອງການຢືນຢັນໃຫ້ລູກຄ້າເຂົ້າໃຊ້ສະໜາມບໍ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ຍົກເລີກ'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check),
              label: const Text('ຢືນຢັນ'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      checkingIn = true;
    });

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/bookings/$id/checkin'),
        headers: authHeaders,
      );

      if (!mounted) return;

      setState(() {
        checkingIn = false;
      });

      if (response.statusCode == 200) {
        showMessage('ແຈ້ງເຂົ້າເດີ່ນສຳເລັດ');
        fetchBookings();
      } else {
        showMessage(
          getMessage(response.body, 'Check-in ບໍ່ສຳເລັດ'),
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        checkingIn = false;
      });

      showMessage('Check-in ຜິດພາດ: $e', isError: true);
    }
  }

  Future<void> pickDate() async {
    final initialDate =
        DateTime.tryParse(dateController.text) ?? DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      dateController.text = formatDateOnly(pickedDate);
      fetchBookings();
    }
  }

  bool canCheckIn(Map booking) {
    final status = booking['status']?.toString() ?? '';
    final payment = booking['payment_status']?.toString() ?? '';

    return status == 'booked' && payment == 'paid';
  }

  List getFilteredBookings() {
    List result = bookings.where((b) {
      final status = b['status']?.toString() ?? '';
      return status != 'cancelled';
    }).toList();

    if (filter == 'ready') {
      result = result.where((b) => canCheckIn(b)).toList();
    }

    if (filter == 'pending_payment') {
      result = result.where((b) {
        final status = b['status']?.toString() ?? '';
        final payment = b['payment_status']?.toString() ?? '';

        return status != 'checked_in' && payment != 'paid';
      }).toList();
    }

    if (filter == 'checked_in') {
      result = result.where((b) {
        final status = b['status']?.toString() ?? '';
        return status == 'checked_in';
      }).toList();
    }

    final keyword = searchController.text.trim().toLowerCase();

    if (keyword.isNotEmpty) {
      result = result.where((b) {
        final customer = b['customer_name']?.toString().toLowerCase() ?? '';
        final phone = b['customer_phone']?.toString().toLowerCase() ?? '';
        final field = b['field_name']?.toString().toLowerCase() ?? '';
        final id = b['id']?.toString().toLowerCase() ?? '';

        return customer.contains(keyword) ||
            phone.contains(keyword) ||
            field.contains(keyword) ||
            id.contains(keyword);
      }).toList();
    }

    return result;
  }

  int countAll() {
    return bookings.where((b) => b['status']?.toString() != 'cancelled').length;
  }

  int countReady() {
    return bookings.where((b) => canCheckIn(b)).length;
  }

  int countPendingPayment() {
    return bookings.where((b) {
      final status = b['status']?.toString() ?? '';
      final payment = b['payment_status']?.toString() ?? '';

      return status != 'cancelled' &&
          status != 'checked_in' &&
          payment != 'paid';
    }).length;
  }

  int countCheckedIn() {
    return bookings.where((b) {
      final status = b['status']?.toString() ?? '';
      return status == 'checked_in';
    }).length;
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
      case 'rejected':
        return 'ປະຕິເສດ';
      case 'partial':
        return 'ຈ່າຍບໍ່ຄົບ';
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
    if (status == 'rejected') return Colors.red;
    if (status == 'partial') return Colors.deepOrange;

    return Colors.orange;
  }

  Widget badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget summaryBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: softCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.green.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget summarySection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 4;

        if (constraints.maxWidth < 1050) columns = 2;
        if (constraints.maxWidth < 620) columns = 1;

        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: columns,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: columns == 4 ? 2.35 : 3.4,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            summaryBox(
              title: 'ລາຍການທັງໝົດ',
              value: countAll().toString(),
              icon: Icons.list_alt,
              color: primaryGreen,
            ),
            summaryBox(
              title: 'ພ້ອມແຈ້ງເຂົ້າ',
              value: countReady().toString(),
              icon: Icons.verified,
              color: Colors.green,
            ),
            summaryBox(
              title: 'ລໍຖ້າຊຳລະ',
              value: countPendingPayment().toString(),
              icon: Icons.hourglass_top,
              color: Colors.orange,
            ),
            summaryBox(
              title: 'ເຂົ້າໃຊ້ແລ້ວ',
              value: countCheckedIn().toString(),
              icon: Icons.login,
              color: Colors.blue,
            ),
          ],
        );
      },
    );
  }

  Widget filterChipButton({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final selected = filter == value;

    return ChoiceChip(
      selected: selected,
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? primaryGreen : Colors.grey,
      ),
      label: Text(label),
      selectedColor: Colors.green.shade100,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? Colors.green.shade300 : Colors.grey.shade200,
      ),
      onSelected: (_) {
        setState(() {
          filter = value;
        });
      },
    );
  }

  Widget filterSection() {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;

          final dateField = SizedBox(
            width: isWide ? 230 : double.infinity,
            child: TextField(
              controller: dateController,
              readOnly: true,
              onTap: pickDate,
              decoration: InputDecoration(
                labelText: 'ເລືອກວັນທີ',
                prefixIcon: const Icon(Icons.calendar_month),
                suffixIcon: const Icon(Icons.arrow_drop_down),
                filled: true,
                fillColor: lightBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );

          final searchField = SizedBox(
            width: isWide ? 330 : double.infinity,
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ຄົ້ນຫາຊື່, ເບີໂທ, ເດີ່ນ...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: lightBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );

          final chips = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                filterChipButton(
                  label: 'ທັງໝົດ',
                  value: 'all',
                  icon: Icons.list_alt,
                ),
                const SizedBox(width: 10),
                filterChipButton(
                  label: 'ພ້ອມ Check-in',
                  value: 'ready',
                  icon: Icons.verified,
                ),
                const SizedBox(width: 10),
                filterChipButton(
                  label: 'ລໍຖ້າຊຳລະ',
                  value: 'pending_payment',
                  icon: Icons.hourglass_top,
                ),
                const SizedBox(width: 10),
                filterChipButton(
                  label: 'ເຂົ້າໃຊ້ແລ້ວ',
                  value: 'checked_in',
                  icon: Icons.login,
                ),
              ],
            ),
          );

          if (!isWide) {
            return Column(
              children: [
                dateField,
                const SizedBox(height: 12),
                searchField,
                const SizedBox(height: 12),
                chips,
              ],
            );
          }

          return Row(
            children: [
              dateField,
              const SizedBox(width: 14),
              searchField,
              const SizedBox(width: 14),
              Expanded(child: chips),
            ],
          );
        },
      ),
    );
  }

  Widget bookingCard(Map booking) {
    final id = booking['id'];
    final status = booking['status']?.toString() ?? 'booked';
    final paymentStatus = booking['payment_status']?.toString() ?? 'pending';
    final ready = canCheckIn(booking);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: softCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ready ? Colors.green.shade200 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;

          final leadingIcon = Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: ready ? Colors.green.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              ready ? Icons.login : Icons.event_note,
              color: ready ? primaryGreen : Colors.grey,
              size: 30,
            ),
          );

          final customerInfo = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BK-$id',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                booking['customer_name']?.toString() ?? '-',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                booking['customer_phone']?.toString() ?? '-',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          );

          final fieldInfo = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking['field_name']?.toString() ?? '-',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${normalizeDate(booking['booking_date'])} | ${normalizeTime(booking['start_time'])} - ${normalizeTime(booking['end_time'])}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${money(booking['total_price'])} ກີບ',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );

          final statusBadges = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              badge(laoStatus(status), statusColor(status)),
              badge(laoPayment(paymentStatus), paymentColor(paymentStatus)),
            ],
          );

          final actionButton = SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ready ? primaryGreen : Colors.grey.shade300,
                foregroundColor: ready ? Colors.white : Colors.grey.shade700,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: ready && !checkingIn ? () => checkIn(id) : null,
              icon: const Icon(Icons.login),
              label: Text(
                status == 'checked_in'
                    ? 'ເຂົ້າໃຊ້ແລ້ວ'
                    : ready
                        ? 'ແຈ້ງເຂົ້າ'
                        : 'ຍັງບໍ່ພ້ອມ',
              ),
            ),
          );

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    leadingIcon,
                    const SizedBox(width: 14),
                    Expanded(child: customerInfo),
                  ],
                ),
                const SizedBox(height: 14),
                fieldInfo,
                const SizedBox(height: 14),
                statusBadges,
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: actionButton,
                ),
              ],
            );
          }

          return Row(
            children: [
              leadingIcon,
              const SizedBox(width: 18),
              Expanded(
                flex: 2,
                child: customerInfo,
              ),
              Expanded(
                flex: 2,
                child: fieldInfo,
              ),
              Expanded(
                flex: 2,
                child: statusBadges,
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 170,
                child: actionButton,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget listSection() {
    final filtered = getFilteredBookings();

    if (loading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(
            color: primaryGreen,
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return Expanded(
        child: Center(
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: softCard,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.green.shade50),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 54,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(height: 14),
                const Text(
                  'ບໍ່ພົບລາຍການ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ບໍ່ມີລາຍການຈອງຕາມເງື່ອນໄຂທີ່ເລືອກ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.separated(
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          return bookingCard(filtered[index]);
        },
      ),
    );
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
            Icons.login,
            color: darkGreen,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ແຈ້ງເຂົ້າເດີ່ນ',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'ກວດສອບການຈອງ, ການຊຳລະ ແລະ ຢືນຢັນເຂົ້າໃຊ້ສະໜາມ',
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
          onPressed: loading ? null : fetchBookings,
          icon: const Icon(Icons.refresh),
          label: const Text('ໂຫຼດຄືນ'),
        ),
      ],
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
          summarySection(),
          const SizedBox(height: 18),
          filterSection(),
          const SizedBox(height: 18),
          listSection(),
        ],
      ),
    );
  }
}

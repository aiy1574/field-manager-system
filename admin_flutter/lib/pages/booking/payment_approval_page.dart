import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const Color primaryGreen = Color(0xFF16A34A);
const Color darkGreen = Color(0xFF0F8A43);
const Color lightBg = Color(0xFFF4F8F1);
const Color softCard = Color(0xFFFFFFFF);

class PaymentApprovalPage extends StatefulWidget {
  final String token;

  const PaymentApprovalPage({
    super.key,
    required this.token,
  });

  @override
  State<PaymentApprovalPage> createState() => _PaymentApprovalPageState();
}

class _PaymentApprovalPageState extends State<PaymentApprovalPage> {
  final String baseUrl = 'http://localhost:4000/api';
  final String serverUrl = 'http://localhost:4000';

  List bookings = [];
  bool loading = true;
  bool processing = false;

  String filter = 'all';

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Map<String, String> get authHeaders {
    return {
      'Authorization': 'Bearer ${widget.token}',
    };
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
        Uri.parse('$baseUrl/bookings'),
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

  String normalizeDate(dynamic value) {
    if (value == null) return '-';

    final text = value.toString();

    if (text.length >= 10) {
      return text.substring(0, 10);
    }

    return text;
  }

  String normalizeTime(dynamic value) {
    if (value == null) return '-';

    final text = value.toString();

    if (text.length >= 5) {
      return text.substring(0, 5);
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

  String laoBookingStatus(String status) {
    switch (status) {
      case 'booked':
        return 'ຈອງແລ້ວ';
      case 'checked_in':
        return 'ເຂົ້າໃຊ້ແລ້ວ';
      case 'cancelled':
        return 'ຍົກເລີກ';
      case 'cancel_requested':
        return 'ຂໍຍົກເລີກ';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  Color paymentColor(String status) {
    if (status == 'paid') return Colors.green;
    if (status == 'rejected') return Colors.red;
    if (status == 'partial') return Colors.deepOrange;
    return Colors.orange;
  }

  Color bookingStatusColor(String status) {
    if (status == 'checked_in') return Colors.green;
    if (status == 'cancelled') return Colors.red;
    if (status == 'cancel_requested') return Colors.deepOrange;
    return Colors.blueGrey;
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

  String imageUrl(dynamic value) {
    final text = value?.toString() ?? '';

    if (text.isEmpty) return '';

    if (text.startsWith('http://') || text.startsWith('https://')) {
      return text;
    }

    if (text.startsWith('/uploads')) {
      return '$serverUrl$text';
    }

    if (text.startsWith('uploads')) {
      return '$serverUrl/$text';
    }

    return '$serverUrl/uploads/$text';
  }

  bool hasSlip(Map booking) {
    final slip = booking['slip_image']?.toString() ?? '';
    return slip.trim().isNotEmpty;
  }

  List getFilteredBookings() {
    List result = bookings.where((booking) {
      final status = booking['status']?.toString() ?? '';
      return status != 'cancelled';
    }).toList();

    if (filter != 'all') {
      result = result.where((booking) {
        final paymentStatus = booking['payment_status']?.toString() ?? '';
        return paymentStatus == filter;
      }).toList();
    }

    final keyword = searchController.text.trim().toLowerCase();

    if (keyword.isNotEmpty) {
      result = result.where((booking) {
        final id = booking['id']?.toString().toLowerCase() ?? '';
        final customer =
            booking['customer_name']?.toString().toLowerCase() ?? '';
        final phone = booking['customer_phone']?.toString().toLowerCase() ?? '';
        final field = booking['field_name']?.toString().toLowerCase() ?? '';

        return id.contains(keyword) ||
            customer.contains(keyword) ||
            phone.contains(keyword) ||
            field.contains(keyword);
      }).toList();
    }

    return result;
  }

  int countStatus(String status) {
    if (status == 'all') {
      return bookings
          .where((b) => b['status']?.toString() != 'cancelled')
          .length;
    }

    return bookings.where((b) {
      final bookingStatus = b['status']?.toString() ?? '';
      final paymentStatus = b['payment_status']?.toString() ?? '';

      return bookingStatus != 'cancelled' && paymentStatus == status;
    }).length;
  }

  Future<void> updatePayment({
    required int bookingId,
    required String action,
    required String confirmTitle,
    required String confirmText,
    required String successMessage,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(confirmTitle),
          content: Text(confirmText),
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
      processing = true;
    });

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/bookings/$bookingId/$action'),
        headers: authHeaders,
      );

      if (!mounted) return;

      setState(() {
        processing = false;
      });

      if (response.statusCode == 200) {
        showMessage(successMessage);
        fetchBookings();
      } else {
        showMessage(
          getMessage(response.body, 'ອັບເດດສະຖານະບໍ່ສຳເລັດ'),
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        processing = false;
      });

      showMessage('ດຳເນີນການຜິດພາດ: $e', isError: true);
    }
  }

  void approvePayment(int id) {
    updatePayment(
      bookingId: id,
      action: 'approve-payment',
      confirmTitle: 'ອະນຸມັດການຊຳລະ',
      confirmText: 'ຕ້ອງການອະນຸມັດການຊຳລະຂອງລາຍການນີ້ບໍ?',
      successMessage: 'ອະນຸມັດການຊຳລະສຳເລັດ',
    );
  }

  void rejectPayment(int id) {
    updatePayment(
      bookingId: id,
      action: 'reject-payment',
      confirmTitle: 'ປະຕິເສດການຊຳລະ',
      confirmText: 'ຕ້ອງການປະຕິເສດສະລິບການຊຳລະນີ້ບໍ?',
      successMessage: 'ປະຕິເສດການຊຳລະສຳເລັດ',
    );
  }

  void partialPayment(int id) {
    updatePayment(
      bookingId: id,
      action: 'partial-payment',
      confirmTitle: 'ບັນທຶກຈ່າຍບໍ່ຄົບ',
      confirmText: 'ຕ້ອງການບັນທຶກວ່າລາຍການນີ້ຈ່າຍບໍ່ຄົບບໍ?',
      successMessage: 'ບັນທຶກຈ່າຍບໍ່ຄົບສຳເລັດ',
    );
  }

  void showSlipDialog(Map booking) {
    final url = imageUrl(booking['slip_image']);

    if (url.isEmpty) {
      showMessage('ບໍ່ພົບຮູບສະລິບ', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: softCard,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green.shade50,
                      child: const Icon(Icons.receipt, color: primaryGreen),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'ຮູບສະລິບການຊຳລະ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    url,
                    height: 520,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        height: 280,
                        alignment: Alignment.center,
                        color: Colors.grey.shade100,
                        child: const Text('ໂຫຼດຮູບສະລິບບໍ່ໄດ້'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            child: Icon(icon, color: color, size: 26),
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
        int columns = 5;

        if (constraints.maxWidth < 1200) columns = 3;
        if (constraints.maxWidth < 760) columns = 2;
        if (constraints.maxWidth < 520) columns = 1;

        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: columns,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: columns >= 3 ? 2.35 : 3.2,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            summaryBox(
              title: 'ທັງໝົດ',
              value: countStatus('all').toString(),
              icon: Icons.list_alt,
              color: primaryGreen,
            ),
            summaryBox(
              title: 'ລໍຖ້າ',
              value: countStatus('pending').toString(),
              icon: Icons.hourglass_top,
              color: Colors.orange,
            ),
            summaryBox(
              title: 'ຊຳລະແລ້ວ',
              value: countStatus('paid').toString(),
              icon: Icons.verified,
              color: Colors.green,
            ),
            summaryBox(
              title: 'ຈ່າຍບໍ່ຄົບ',
              value: countStatus('partial').toString(),
              icon: Icons.warning_amber,
              color: Colors.deepOrange,
            ),
            summaryBox(
              title: 'ປະຕິເສດ',
              value: countStatus('rejected').toString(),
              icon: Icons.cancel,
              color: Colors.red,
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
          final isWide = constraints.maxWidth >= 920;

          final searchField = SizedBox(
            width: isWide ? 360 : double.infinity,
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ຄົ້ນຫາລູກຄ້າ, ເບີໂທ, ເດີ່ນ...',
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
                  label: 'ລໍຖ້າ',
                  value: 'pending',
                  icon: Icons.hourglass_top,
                ),
                const SizedBox(width: 10),
                filterChipButton(
                  label: 'ຊຳລະແລ້ວ',
                  value: 'paid',
                  icon: Icons.verified,
                ),
                const SizedBox(width: 10),
                filterChipButton(
                  label: 'ຈ່າຍບໍ່ຄົບ',
                  value: 'partial',
                  icon: Icons.warning_amber,
                ),
                const SizedBox(width: 10),
                filterChipButton(
                  label: 'ປະຕິເສດ',
                  value: 'rejected',
                  icon: Icons.cancel,
                ),
              ],
            ),
          );

          if (!isWide) {
            return Column(
              children: [
                searchField,
                const SizedBox(height: 12),
                chips,
              ],
            );
          }

          return Row(
            children: [
              searchField,
              const SizedBox(width: 14),
              Expanded(child: chips),
            ],
          );
        },
      ),
    );
  }

  Widget slipPreview(Map booking) {
    final url = imageUrl(booking['slip_image']);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: hasSlip(booking) ? () => showSlipDialog(booking) : null,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: hasSlip(booking)
            ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                ),
              )
            : const Center(
                child: Icon(
                  Icons.receipt_long,
                  color: Colors.grey,
                  size: 40,
                ),
              ),
      ),
    );
  }

  Widget actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed == null ? Colors.grey.shade300 : color,
          foregroundColor:
              onPressed == null ? Colors.grey.shade700 : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        onPressed: processing ? null : onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }

  Widget paymentCard(Map booking) {
    final id = int.tryParse(booking['id'].toString()) ?? 0;
    final paymentStatus = booking['payment_status']?.toString() ?? 'pending';
    final bookingStatus = booking['status']?.toString() ?? 'booked';

    final canApprove = paymentStatus != 'paid' && bookingStatus != 'cancelled';
    final canReject = paymentStatus != 'rejected' &&
        paymentStatus != 'paid' &&
        bookingStatus != 'cancelled';
    final canPartial = paymentStatus != 'partial' &&
        paymentStatus != 'paid' &&
        bookingStatus != 'cancelled';

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
          final isWide = constraints.maxWidth >= 900;

          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking['field_name']?.toString() ?? '-',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ລູກຄ້າ: ${booking['customer_name'] ?? '-'}',
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'ເບີໂທ: ${booking['customer_phone'] ?? '-'}',
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'ວັນທີ: ${normalizeDate(booking['booking_date'])}',
              ),
              const SizedBox(height: 4),
              Text(
                'ເວລາ: ${normalizeTime(booking['start_time'])} - ${normalizeTime(booking['end_time'])}',
              ),
              const SizedBox(height: 4),
              Text(
                'ຈຳນວນເງິນ: ${money(booking['total_price'])} ກີບ',
                style: const TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  badge(laoPayment(paymentStatus), paymentColor(paymentStatus)),
                  badge(
                    laoBookingStatus(bookingStatus),
                    bookingStatusColor(bookingStatus),
                  ),
                  if (!hasSlip(booking)) badge('ບໍ່ມີສະລິບ', Colors.grey),
                ],
              ),
            ],
          );

          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              actionButton(
                label: 'ອະນຸມັດ',
                icon: Icons.check,
                color: primaryGreen,
                onPressed: canApprove ? () => approvePayment(id) : null,
              ),
              actionButton(
                label: 'ຈ່າຍບໍ່ຄົບ',
                icon: Icons.warning_amber,
                color: Colors.deepOrange,
                onPressed: canPartial ? () => partialPayment(id) : null,
              ),
              actionButton(
                label: 'ປະຕິເສດ',
                icon: Icons.close,
                color: Colors.red,
                onPressed: canReject ? () => rejectPayment(id) : null,
              ),
            ],
          );

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: slipPreview(booking)),
                const SizedBox(height: 16),
                info,
                const SizedBox(height: 16),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              slipPreview(booking),
              const SizedBox(width: 18),
              Expanded(child: info),
              const SizedBox(width: 18),
              SizedBox(
                width: 360,
                child: actions,
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
          child: CircularProgressIndicator(color: primaryGreen),
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
                  Icons.receipt_long,
                  size: 54,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(height: 14),
                const Text(
                  'ບໍ່ພົບລາຍການຊຳລະ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ລອງປ່ຽນຕົວກອງ ຫຼື ກົດໂຫຼດຄືນ',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
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
          return paymentCard(filtered[index]);
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
            Icons.receipt_long,
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
                'ກວດສອບການຊຳລະ',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'ກວດສອບສະລິບ ແລະ ອະນຸມັດສະຖານະການຊຳລະ',
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

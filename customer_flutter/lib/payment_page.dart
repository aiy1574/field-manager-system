import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

const Color primaryGreen = Color(0xFF16A34A);
const Color lightBg = Color(0xFFF4F8F1);

class PaymentPage extends StatefulWidget {
  final String token;
  final Map customer;
  final Map field;
  final String bookingDate;
  final Map slot;
  final String note;

  const PaymentPage({
    super.key,
    required this.token,
    required this.customer,
    required this.field,
    required this.bookingDate,
    required this.slot,
    required this.note,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  XFile? selectedSlip;
  bool loading = false;

  int get price {
    final value = widget.slot['price'];
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return double.tryParse(value.toString())?.toInt() ?? 0;
  }

  Future<void> pickSlip() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedSlip = image;
      });
    }
  }

  Future<String?> uploadSlip() async {
    if (selectedSlip == null) return null;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://localhost:4000/api/upload'),
    );

    final bytes = await selectedSlip!.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes(
        'slip',
        bytes,
        filename: selectedSlip!.name,
      ),
    );

    final response = await request.send().timeout(
      const Duration(seconds: 20),
    );

    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(body);
      return data['path'];
    }

    throw Exception(body);
  }

  Future<void> confirmPaymentBooking() async {
    if (selectedSlip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ກະລຸນາເລືອກສະລິບການໂອນ')),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final slipPath = await uploadSlip();

      if (slipPath == null) {
        throw Exception('Upload slip failed');
      }

      final response = await http
          .post(
            Uri.parse('http://localhost:4000/api/bookings'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.token}',
            },
            body: jsonEncode({
              'field_id': widget.field['id'],
              'customer_id': widget.customer['id'],
              'booking_date': widget.bookingDate,
              'start_time': widget.slot['start'],
              'end_time': widget.slot['end'],
              'total_price': price,
              'note': widget.note,
              'slip_image': slipPath,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ຈອງສະໜາມສຳເລັດ')),
        );

        Navigator.pop(context);
        Navigator.pop(context);
      } else if (response.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ເວລານີ້ຖືກຈອງແລ້ວ')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.body)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ມີຂໍ້ຜິດພາດ: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Widget summaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slotLabel = widget.slot['label'] ?? '';
    final slipName = selectedSlip?.name ?? '';

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: const Text('ຊຳລະເງິນ'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Text(
                    '$price ກີບ',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('ຍອດທີ່ຕ້ອງຊຳລະ'),
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/images/qr.jpeg',
                    height: 260,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'ສະແກນ QR ເພື່ອຊຳລະ',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text('ST Football Field'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
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
                    'ລາຍລະອຽດການຈອງ',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 24),
                  summaryRow('ສະໜາມ', widget.field['name'] ?? '-'),
                  summaryRow('ວັນທີ', widget.bookingDate),
                  summaryRow('ເວລາ', slotLabel.toString()),
                  summaryRow('ລາຄາລວມ', '$price ກີບ'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              onTap: pickSlip,
              leading: const Icon(Icons.image, color: primaryGreen),
              title: Text(
                selectedSlip == null
                    ? 'ອັບໂຫຼດສະລິບການໂອນ'
                    : 'ເລືອກແລ້ວ: $slipName',
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
          const SizedBox(height: 26),
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
              onPressed: loading ? null : confirmPaymentBooking,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'ຢືນຢັນການຈອງ',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
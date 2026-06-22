import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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

    request.files.add(
      await http.MultipartFile.fromPath(
        'slip',
        selectedSlip!.path,
      ),
    );

    final response = await request.send();

    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);
      return data['path'];
    }

    return null;
  }

  Future<void> confirmPaymentBooking() async {
    if (selectedSlip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose payment slip')),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final slipPath = await uploadSlip();

    if (slipPath == null) {
      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload slip failed')),
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
        'field_id': widget.field['id'],
        'customer_id': widget.customer['id'],
        'booking_date': widget.bookingDate,
        'start_time': widget.slot['start'],
        'end_time': widget.slot['end'],
        'total_price': 500,
        'note': widget.note,
        'slip_image': slipPath,
      }),
    );

    setState(() {
      loading = false;
    });

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking success')),
      );

      Navigator.pop(context);
      Navigator.pop(context);
    } else if (response.statusCode == 409) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This time is already booked')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.body)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slotLabel = widget.slot['label'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/qr.jpeg',
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Scan QR to Pay',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'ST Football Field',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Detail',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  Text('Field: ${widget.field['name'] ?? ''}'),
                  const SizedBox(height: 8),
                  Text('Date: ${widget.bookingDate}'),
                  const SizedBox(height: 8),
                  Text('Time: $slotLabel'),
                  const SizedBox(height: 8),
                  const Text('Price: 500'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          OutlinedButton.icon(
            onPressed: pickSlip,
            icon: const Icon(Icons.image),
            label: Text(
              selectedSlip == null
                  ? 'Choose payment slip'
                  : 'Slip selected: ${selectedSlip!.name}',
            ),
          ),

          const SizedBox(height: 12),

          if (selectedSlip != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Selected slip: ${selectedSlip!.name}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 30),

          SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: loading ? null : confirmPaymentBooking,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Confirm Booking',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const Color primaryGreen = Color(0xFF16A34A);
const Color lightBg = Color(0xFFF4F8F1);

class EditProfilePage extends StatefulWidget {
  final String token;
  final Map customer;

  const EditProfilePage({
    super.key,
    required this.token,
    required this.customer,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  bool loading = false;

  @override
  void initState() {
    super.initState();

    fullNameController.text = widget.customer['full_name'] ?? '';
    phoneController.text = widget.customer['phone'] ?? '';
    emailController.text = widget.customer['email'] ?? '';
  }

  Future<void> updateProfile() async {
    setState(() {
      loading = true;
    });

    try {
      final response = await http.put(
        Uri.parse('http://localhost:4000/api/customers/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'id': widget.customer['id'],
          'full_name': fullNameController.text.trim(),
          'phone': phoneController.text.trim(),
          'email': emailController.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ແກ້ໄຂຂໍ້ມູນສຳເລັດ')),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.body)),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ຜິດພາດ: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Widget inputBox({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryGreen),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: const Text('ແກ້ໄຂຂໍ້ມູນ'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          inputBox(
            label: 'ຊື່',
            controller: fullNameController,
            icon: Icons.person,
          ),
          const SizedBox(height: 16),
          inputBox(
            label: 'ເບີໂທ',
            controller: phoneController,
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          inputBox(
            label: 'ອີເມວ',
            controller: emailController,
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: loading ? null : updateProfile,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'ບັນທຶກ',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const Color primaryGreen = Color(0xFF16A34A);
const Color lightBg = Color(0xFFF4F8F1);

class ChangePasswordPage extends StatefulWidget {
  final String token;
  final Map customer;

  const ChangePasswordPage({
    super.key,
    required this.token,
    required this.customer,
  });

  @override
  State<ChangePasswordPage> createState() =>
      _ChangePasswordPageState();
}

class _ChangePasswordPageState
    extends State<ChangePasswordPage> {
  final oldPasswordController =
      TextEditingController();

  final newPasswordController =
      TextEditingController();

  final confirmPasswordController =
      TextEditingController();

  bool loading = false;

  Future<void> changePassword() async {
    if (newPasswordController.text !=
        confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ລະຫັດຜ່ານໃໝ່ບໍ່ກົງກັນ',
          ),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final response = await http.patch(
        Uri.parse(
          'http://localhost:4000/api/customers/change-password',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': widget.customer['id'],
          'old_password':
              oldPasswordController.text,
          'new_password':
              newPasswordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'ປ່ຽນລະຫັດຜ່ານສຳເລັດ',
            ),
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(response.body),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Widget inputBox(
    String title,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: title,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: const Text(
          'ປ່ຽນລະຫັດຜ່ານ',
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          inputBox(
            'ລະຫັດຜ່ານເກົ່າ',
            oldPasswordController,
          ),

          const SizedBox(height: 15),

          inputBox(
            'ລະຫັດຜ່ານໃໝ່',
            newPasswordController,
          ),

          const SizedBox(height: 15),

          inputBox(
            'ຢືນຢັນລະຫັດຜ່ານໃໝ່',
            confirmPasswordController,
          ),

          const SizedBox(height: 25),

          SizedBox(
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    primaryGreen,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: loading
                  ? null
                  : changePassword,
              child: loading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text(
                      'ບັນທຶກ',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
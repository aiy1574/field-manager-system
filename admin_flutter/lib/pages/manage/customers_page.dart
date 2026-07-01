import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const Color primaryGreen = Color(0xFF16A34A);
const Color darkGreen = Color(0xFF0F8A43);
const Color lightBg = Color(0xFFF4F8F1);
const Color softCard = Color(0xFFFFFFFF);

class CustomersPage extends StatefulWidget {
  final String token;

  const CustomersPage({
    super.key,
    required this.token,
  });

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final String baseUrl = 'http://localhost:4000/api';

  List customers = [];
  List filteredCustomers = [];
  bool loading = true;

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCustomers();
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

  Map<String, String> get jsonHeaders {
    return {
      'Authorization': 'Bearer ${widget.token}',
      'Content-Type': 'application/json',
    };
  }

  Future<void> fetchCustomers() async {
    setState(() {
      loading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers'),
        headers: authHeaders,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          customers = data is List ? data : [];
          loading = false;
        });

        searchCustomers(searchController.text);
      } else {
        setState(() {
          loading = false;
        });

        showMessage(
          getMessage(response.body, 'ໂຫຼດຂໍ້ມູນລູກຄ້າບໍ່ສຳເລັດ'),
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

  void searchCustomers(String value) {
    final keyword = value.trim().toLowerCase();

    setState(() {
      if (keyword.isEmpty) {
        filteredCustomers = customers;
      } else {
        filteredCustomers = customers.where((customer) {
          final name = (customer['full_name'] ?? '').toString().toLowerCase();
          final phone = (customer['phone'] ?? '').toString().toLowerCase();
          final email = (customer['email'] ?? '').toString().toLowerCase();
          final note = (customer['note'] ?? '').toString().toLowerCase();

          return name.contains(keyword) ||
              phone.contains(keyword) ||
              email.contains(keyword) ||
              note.contains(keyword);
        }).toList();
      }
    });
  }

  String formatDate(dynamic value) {
    if (value == null) return '-';

    final text = value.toString();

    if (text.length >= 10) {
      return text.substring(0, 10);
    }

    return text;
  }

  Widget activeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'ໃຊ້ງານ',
        style: TextStyle(
          color: primaryGreen,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Future<void> updateCustomer(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl/customers/$id'),
      headers: jsonHeaders,
      body: jsonEncode(body),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      showMessage('ແກ້ໄຂຂໍ້ມູນລູກຄ້າສຳເລັດ');
      fetchCustomers();
    } else {
      showMessage(
        getMessage(response.body, 'ແກ້ໄຂບໍ່ສຳເລັດ'),
        isError: true,
      );
    }
  }

  Future<void> changePassword(int id, String password) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/customers/$id/password'),
      headers: jsonHeaders,
      body: jsonEncode({
        'password': password,
      }),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      showMessage('ປ່ຽນ Password ສຳເລັດ');
      fetchCustomers();
    } else {
      showMessage(
        getMessage(response.body, 'ປ່ຽນ Password ບໍ່ສຳເລັດ'),
        isError: true,
      );
    }
  }

  Future<void> deleteCustomer(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('ຢືນຢັນລຶບລູກຄ້າ'),
          content: const Text(
            'ຖ້າລູກຄ້າຄົນນີ້ມີປະຫວັດການຈອງ ລະບົບຈະບໍ່ໃຫ້ລຶບ. ຕ້ອງການລຶບບໍ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ຍົກເລີກ'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete),
              label: const Text('ລຶບ'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final response = await http.delete(
      Uri.parse('$baseUrl/customers/$id'),
      headers: authHeaders,
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      showMessage('ລຶບລູກຄ້າສຳເລັດ');
      fetchCustomers();
    } else {
      showMessage(
        getMessage(response.body, 'ລຶບລູກຄ້າບໍ່ສຳເລັດ'),
        isError: true,
      );
    }
  }

  void showCustomerDialog(Map customer) {
    final nameController = TextEditingController(
      text: customer['full_name']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: customer['phone']?.toString() ?? '',
    );
    final emailController = TextEditingController(
      text: customer['email']?.toString() ?? '',
    );
    final noteController = TextEditingController(
      text: customer['note']?.toString() ?? '',
    );
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('ແກ້ໄຂຂໍ້ມູນລູກຄ້າ'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'ຊື່ລູກຄ້າ',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'ເບີໂທ',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'ໝາຍເຫດ',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password ໃໝ່ (ບໍ່ປ້ອນກໍບໍ່ປ່ຽນ)',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ຍົກເລີກ'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                final password = passwordController.text.trim();

                if (name.isEmpty || phone.isEmpty) {
                  showMessage('ກະລຸນາປ້ອນຊື່ ແລະ ເບີໂທ', isError: true);
                  return;
                }

                Navigator.pop(context);

                final id = int.parse(customer['id'].toString());

                await updateCustomer(id, {
                  'full_name': name,
                  'phone': phone,
                  'email': emailController.text.trim(),
                  'note': noteController.text.trim(),
                });

                if (password.isNotEmpty) {
                  await changePassword(id, password);
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('ບັນທຶກ'),
            ),
          ],
        );
      },
    );
  }

  Widget actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withOpacity(0.18),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.14),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  void showActionMenu(Map customer) {
    final id = int.parse(customer['id'].toString());
    final name = customer['full_name']?.toString() ?? '-';

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green.shade50,
                child: const Icon(Icons.person, color: primaryGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 430,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                actionTile(
                  icon: Icons.edit,
                  title: 'ແກ້ໄຂຂໍ້ມູນ',
                  subtitle: 'ແກ້ໄຂຊື່, ເບີໂທ, email ແລະ password',
                  color: primaryGreen,
                  onTap: () {
                    Navigator.pop(context);
                    showCustomerDialog(customer);
                  },
                ),
                const SizedBox(height: 12),
                actionTile(
                  icon: Icons.delete,
                  title: 'ລຶບລູກຄ້າ',
                  subtitle: 'ລຶບໄດ້ສະເພາະລູກຄ້າທີ່ບໍ່ມີປະຫວັດການຈອງ',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    deleteCustomer(id);
                  },
                ),
              ],
            ),
          ),
        );
      },
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
            Icons.people,
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
                'ຈັດການລູກຄ້າ',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'ກວດສອບ ແລະ ແກ້ໄຂຂໍ້ມູນລູກຄ້າ',
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
          onPressed: fetchCustomers,
          icon: const Icon(Icons.refresh),
          label: const Text('ໂຫຼດຄືນ'),
        ),
      ],
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
      child: TextField(
        controller: searchController,
        onChanged: searchCustomers,
        decoration: InputDecoration(
          hintText: 'ຄົ້ນຫາຊື່, ອີເມວ, ເບີໂທ ຫຼື ໝາຍເຫດ...',
          prefixIcon: const Icon(
            Icons.search,
            color: primaryGreen,
          ),
          filled: true,
          fillColor: lightBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: primaryGreen,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget customersTable() {
    if (loading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(
            color: primaryGreen,
          ),
        ),
      );
    }

    if (filteredCustomers.isEmpty) {
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
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 52, color: Colors.grey),
                SizedBox(height: 14),
                Text(
                  'ບໍ່ພົບຂໍ້ມູນລູກຄ້າ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
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
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowHeight: 58,
                          dataRowMinHeight: 66,
                          dataRowMaxHeight: 78,
                          columnSpacing: 34,
                          headingRowColor: WidgetStateProperty.all(
                            Colors.green.shade50,
                          ),
                          columns: const [
                            DataColumn(label: Text('ລະຫັດ')),
                            DataColumn(label: Text('ລູກຄ້າ')),
                            DataColumn(label: Text('ຂໍ້ມູນຕິດຕໍ່')),
                            DataColumn(label: Text('ໝາຍເຫດ')),
                            DataColumn(label: Text('ວັນທີສະໝັກ')),
                            DataColumn(label: Text('ສະຖານະ')),
                            DataColumn(label: Text('ຈັດການ')),
                          ],
                          rows: filteredCustomers.map((customer) {
                            final id = customer['id'] ?? '-';
                            final name =
                                customer['full_name']?.toString() ?? '-';
                            final phone = customer['phone']?.toString() ?? '-';
                            final email = customer['email']?.toString() ?? '-';
                            final note = customer['note']?.toString() ?? '-';

                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    'CUST-${id.toString().padLeft(3, '0')}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primaryGreen,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 160,
                                    child: Text(
                                      name.isEmpty ? '-' : name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 220,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          email.isEmpty ? '-' : email,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          phone.isEmpty ? '-' : phone,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 190,
                                    child: Text(
                                      note.isEmpty ? '-' : note,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(formatDate(customer['created_at'])),
                                ),
                                DataCell(activeBadge()),
                                DataCell(
                                  IconButton(
                                    tooltip: 'ຈັດການ',
                                    icon: const Icon(Icons.more_vert),
                                    color: primaryGreen,
                                    onPressed: () => showActionMenu(customer),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'ສະແດງ ${filteredCustomers.length} ຈາກ ${customers.length} ລາຍການ',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Customer Mobile App',
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          filterSection(),
          const SizedBox(height: 18),
          customersTable(),
        ],
      ),
    );
  }
}

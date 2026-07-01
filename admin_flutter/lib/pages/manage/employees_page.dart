import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const Color primaryGreen = Color(0xFF16A34A);
const Color darkGreen = Color(0xFF0F8A43);
const Color lightBg = Color(0xFFF4F8F1);
const Color softCard = Color(0xFFFFFFFF);

class EmployeesPage extends StatefulWidget {
  final String token;

  const EmployeesPage({
    super.key,
    required this.token,
  });

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  final String baseUrl = 'http://localhost:4000/api';

  List employees = [];
  bool loading = true;

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchEmployees();
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

  Future<void> fetchEmployees() async {
    setState(() {
      loading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/employees'),
        headers: authHeaders,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          employees = jsonDecode(response.body);
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

  List getFilteredEmployees() {
    final keyword = searchController.text.trim().toLowerCase();

    if (keyword.isEmpty) return employees;

    return employees.where((e) {
      final name = e['full_name']?.toString().toLowerCase() ?? '';
      final email = e['email']?.toString().toLowerCase() ?? '';
      final phone = e['phone']?.toString().toLowerCase() ?? '';
      final role = e['role']?.toString().toLowerCase() ?? '';

      return name.contains(keyword) ||
          email.contains(keyword) ||
          phone.contains(keyword) ||
          role.contains(keyword);
    }).toList();
  }

  String formatDate(dynamic value) {
    if (value == null) return '-';

    final text = value.toString();

    if (text.length >= 10) {
      return text.substring(0, 10);
    }

    return text;
  }

  String roleText(String role) {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'admin':
        return 'Admin';
      case 'staff':
        return 'Staff';
      case 'sales':
        return 'Sales';
      case 'checkin':
        return 'Check-in';
      default:
        return role.isEmpty ? '-' : role;
    }
  }

  Color roleColor(String role) {
    if (role == 'owner' || role == 'admin') return primaryGreen;
    if (role == 'sales') return Colors.blue;
    if (role == 'checkin') return Colors.deepPurple;
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

  Future<void> createEmployee(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl/employees'),
      headers: jsonHeaders,
      body: jsonEncode(body),
    );

    if (!mounted) return;

    if (response.statusCode == 201) {
      showMessage('ເພີ່ມພະນັກງານສຳເລັດ');
      fetchEmployees();
    } else {
      showMessage(
        getMessage(response.body, 'ເພີ່ມບໍ່ສຳເລັດ'),
        isError: true,
      );
    }
  }

  Future<void> updateEmployee(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl/employees/$id'),
      headers: jsonHeaders,
      body: jsonEncode(body),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      showMessage('ແກ້ໄຂພະນັກງານສຳເລັດ');
      fetchEmployees();
    } else {
      showMessage(
        getMessage(response.body, 'ແກ້ໄຂບໍ່ສຳເລັດ'),
        isError: true,
      );
    }
  }

  Future<void> changePassword(int id, String password) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/employees/$id/password'),
      headers: jsonHeaders,
      body: jsonEncode({
        'password': password,
      }),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      showMessage('ປ່ຽນລະຫັດຜ່ານສຳເລັດ');
      fetchEmployees();
    } else {
      showMessage(
        getMessage(response.body, 'ປ່ຽນລະຫັດຜ່ານບໍ່ສຳເລັດ'),
        isError: true,
      );
    }
  }

  Future<void> deleteEmployee(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('ຢືນຢັນປິດການໃຊ້ງານ'),
          content: const Text(
            'ຕ້ອງການປິດການໃຊ້ງານພະນັກງານຄົນນີ້ບໍ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ຍົກເລີກ'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ຢືນຢັນ'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final response = await http.delete(
      Uri.parse('$baseUrl/employees/$id'),
      headers: authHeaders,
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      showMessage('ປິດການໃຊ້ງານສຳເລັດ');
      fetchEmployees();
    } else {
      showMessage(
        getMessage(response.body, 'ປິດການໃຊ້ງານບໍ່ສຳເລັດ'),
        isError: true,
      );
    }
  }

  void showEmployeeDialog({Map? employee}) {
    final isEdit = employee != null;

    final nameController = TextEditingController(
      text: employee?['full_name']?.toString() ?? '',
    );
    final emailController = TextEditingController(
      text: employee?['email']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: employee?['phone']?.toString() ?? '',
    );
    final positionController = TextEditingController(
      text: employee?['position']?.toString() ?? '',
    );
    final passwordController = TextEditingController();

    String selectedRole = employee?['role']?.toString() ?? 'staff';
    bool isActive = (employee?['is_active'] ?? 1).toString() != '0';

    final roleOptions = ['owner', 'admin', 'staff', 'sales', 'checkin'];

    if (!roleOptions.contains(selectedRole)) {
      selectedRole = 'staff';
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEdit ? 'ແກ້ໄຂພະນັກງານ' : 'ເພີ່ມພະນັກງານ',
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'ຊື່ພະນັກງານ',
                          prefixIcon: Icon(Icons.person),
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
                        controller: positionController,
                        decoration: const InputDecoration(
                          labelText: 'ຕຳແໜ່ງ',
                          prefixIcon: Icon(Icons.badge),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          prefixIcon: Icon(Icons.admin_panel_settings),
                          border: OutlineInputBorder(),
                        ),
                        items: roleOptions.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(roleText(role)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedRole = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: isEdit
                              ? 'ລະຫັດຜ່ານໃໝ່ (ບໍ່ປ້ອນກໍບໍ່ປ່ຽນ)'
                              : 'ລະຫັດຜ່ານ',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: isActive,
                        activeColor: primaryGreen,
                        title: const Text('ເປີດການໃຊ້ງານ'),
                        subtitle: Text(
                          isActive
                              ? 'ບັນຊີນີ້ສາມາດເຂົ້າລະບົບໄດ້'
                              : 'ບັນຊີນີ້ຖືກປິດການໃຊ້ງານ',
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            isActive = value;
                          });
                        },
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
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();

                    if (name.isEmpty || email.isEmpty) {
                      showMessage(
                        'ກະລຸນາປ້ອນຊື່ ແລະ Email',
                        isError: true,
                      );
                      return;
                    }

                    if (!isEdit && password.isEmpty) {
                      showMessage(
                        'ກະລຸນາປ້ອນລະຫັດຜ່ານ',
                        isError: true,
                      );
                      return;
                    }

                    Navigator.pop(context);

                    final body = {
                      'full_name': name,
                      'email': email,
                      'phone': phoneController.text.trim(),
                      'position': positionController.text.trim(),
                      'role': selectedRole,
                      'is_active': isActive ? 1 : 0,
                    };

                    if (isEdit) {
                      final id = int.parse(employee['id'].toString());
                      await updateEmployee(id, body);

                      if (password.isNotEmpty) {
                        await changePassword(id, password);
                      }
                    } else {
                      body['password'] = password;
                      await createEmployee(body);
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('ບັນທຶກ'),
                ),
              ],
            );
          },
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
            Icons.badge,
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
                'ຂໍ້ມູນພະນັກງານ',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'ຈັດການຜູ້ໃຊ້ Owner / Admin / Staff',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          onPressed: () => showEmployeeDialog(),
          icon: const Icon(Icons.add),
          label: const Text('ເພີ່ມພະນັກງານ'),
        ),
        const SizedBox(width: 12),
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
          onPressed: fetchEmployees,
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
      ),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: 'ຄົ້ນຫາພະນັກງານ',
          hintText: 'ຊື່, email, ເບີໂທ ຫຼື role',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: lightBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onChanged: (_) {
          setState(() {});
        },
      ),
    );
  }

  Widget employeesTable() {
    final filtered = getFilteredEmployees();

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
                  Icons.people_outline,
                  size: 52,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(height: 14),
                const Text(
                  'ບໍ່ພົບຂໍ້ມູນພະນັກງານ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ກວດສອບຄຳຄົ້ນຫາ ຫຼື ກົດເພີ່ມພະນັກງານໃໝ່',
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
      child: Container(
        decoration: BoxDecoration(
          color: softCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.green.shade50),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 1150,
            ),
            child: SingleChildScrollView(
              child: DataTable(
                headingRowHeight: 58,
                dataRowMinHeight: 72,
                dataRowMaxHeight: 86,
                columns: const [
                  DataColumn(label: Text('ລະຫັດ')),
                  DataColumn(label: Text('ພະນັກງານ')),
                  DataColumn(label: Text('ເບີໂທ')),
                  DataColumn(label: Text('ຕຳແໜ່ງ')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('ສະຖານະ')),
                  DataColumn(label: Text('ວັນທີສ້າງ')),
                  DataColumn(label: Text('ຈັດການ')),
                ],
                rows: filtered.map((employee) {
                  final id = employee['id'];
                  final role = employee['role']?.toString() ?? '';
                  final isActive =
                      (employee['is_active'] ?? 1).toString() != '0';

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          'EMP-$id',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 230,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                employee['full_name'] ?? '-',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                employee['email'] ?? '-',
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
                          width: 140,
                          child: Text(
                            employee['phone'] ?? '-',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(
                            employee['position'] ?? '-',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 115,
                          child: badge(
                            roleText(role),
                            roleColor(role),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 120,
                          child: badge(
                            isActive ? 'ເປີດໃຊ້ງານ' : 'ປິດໃຊ້ງານ',
                            isActive ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 120,
                          child: Text(
                            formatDate(employee['created_at']),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 185,
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: 'ແກ້ໄຂ',
                                onPressed: () {
                                  showEmployeeDialog(employee: employee);
                                },
                                icon: const Icon(
                                  Icons.edit,
                                  color: primaryGreen,
                                ),
                              ),
                              IconButton(
                                tooltip: 'ປິດການໃຊ້ງານ',
                                onPressed: isActive
                                    ? () {
                                        deleteEmployee(
                                          int.parse(id.toString()),
                                        );
                                      }
                                    : null,
                                icon: Icon(
                                  Icons.block,
                                  color: isActive ? Colors.red : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
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
          employeesTable(),
        ],
      ),
    );
  }
}

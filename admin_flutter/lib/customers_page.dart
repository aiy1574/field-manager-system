import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'theme.dart';

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
  List customers = [];
  List filteredCustomers = [];
  bool loading = true;

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    setState(() {
      loading = true;
    });

    final response = await http.get(
      Uri.parse('http://localhost:4000/api/customers'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        customers = data;
        filteredCustomers = data;
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  void searchCustomers(String value) {
    final keyword = value.toLowerCase();

    setState(() {
      filteredCustomers = customers.where((customer) {
        final name = (customer['full_name'] ?? '').toString().toLowerCase();
        final phone = (customer['phone'] ?? '').toString().toLowerCase();
        final email = (customer['email'] ?? '').toString().toLowerCase();

        return name.contains(keyword) ||
            phone.contains(keyword) ||
            email.contains(keyword);
      }).toList();
    });
  }

  String formatDate(dynamic value) {
    if (value == null) return '-';
    final text = value.toString();
    if (text.length >= 10) return text.substring(0, 10);
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: lightBg,
      child: Padding(
        padding: const EdgeInsets.all(34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'ຈັດການລູກຄ້າ',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: fetchCustomers,
                  icon: const Icon(Icons.refresh),
                  label: const Text('ໂຫຼດຄືນ'),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Expanded(
              child: Card(
                elevation: 3,
                color: Colors.white,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 520,
                            child: TextField(
                              controller: searchController,
                              onChanged: searchCustomers,
                              decoration: InputDecoration(
                                hintText: 'ຄົ້ນຫາຊື່, ອີເມວ ຫຼື ເບີໂທ...',
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
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: primaryGreen,
                              ),
                            )
                          : filteredCustomers.isEmpty
                              ? const Center(
                                  child: Text('ບໍ່ພົບຂໍ້ມູນລູກຄ້າ'),
                                )
                              : SingleChildScrollView(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: DataTable(
                                      headingRowHeight: 58,
                                      dataRowMinHeight: 66,
                                      dataRowMaxHeight: 76,
                                      headingRowColor:
                                          WidgetStateProperty.all(
                                        Colors.green.shade50,
                                      ),
                                      columns: const [
                                        DataColumn(label: Text('ລະຫັດ')),
                                        DataColumn(label: Text('ຊື່ລູກຄ້າ')),
                                        DataColumn(
                                          label: Text('ຂໍ້ມູນຕິດຕໍ່'),
                                        ),
                                        DataColumn(
                                          label: Text('ວັນທີສະໝັກ'),
                                        ),
                                        DataColumn(label: Text('ສະຖານະ')),
                                        DataColumn(label: Text('ຈັດການ')),
                                      ],
                                      rows: filteredCustomers.map((customer) {
                                        final id = customer['id'] ?? '-';
                                        final name =
                                            customer['full_name'] ?? '-';
                                        final phone = customer['phone'] ?? '-';
                                        final email = customer['email'] ?? '-';

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
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(email),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    phone,
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                formatDate(
                                                  customer['created_at'],
                                                ),
                                              ),
                                            ),
                                            DataCell(activeBadge()),
                                            DataCell(
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.more_vert,
                                                ),
                                                color: primaryGreen,
                                                onPressed: () {},
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Text(
                            'ສະແດງ ${filteredCustomers.length} ຈາກ ${customers.length} ລາຍການ',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const Spacer(),
                          OutlinedButton(
                            onPressed: () {},
                            child: const Text('ກ່ອນໜ້າ'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {},
                            child: const Text('1'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {},
                            child: const Text('ຖັດໄປ'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  Future<void> fetchCustomers() async {
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

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Customer Management",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 26),
          Expanded(
            child: Card(
              elevation: 3,
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
                              hintText: "Search by name, email or phone...",
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: fetchCustomers,
                          icon: const Icon(Icons.filter_list),
                          label: const Text("Filter"),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredCustomers.isEmpty
                            ? const Center(child: Text("No customers found"))
                            : SingleChildScrollView(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: DataTable(
                                    headingRowHeight: 58,
                                    dataRowMinHeight: 66,
                                    dataRowMaxHeight: 76,
                                    columns: const [
                                      DataColumn(label: Text("Customer ID")),
                                      DataColumn(label: Text("Name")),
                                      DataColumn(label: Text("Contact Info")),
                                      DataColumn(label: Text("Joined Date")),
                                      DataColumn(label: Text("Status")),
                                      DataColumn(label: Text("Actions")),
                                    ],
                                    rows: filteredCustomers.map((customer) {
                                      final id = customer['id'] ?? '-';
                                      final name = customer['full_name'] ?? '-';
                                      final phone = customer['phone'] ?? '-';
                                      final email = customer['email'] ?? '-';

                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              "CUST-${id.toString().padLeft(3, '0')}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
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
                                            Text(formatDate(
                                                customer['created_at'])),
                                          ),
                                          DataCell(
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                "Active",
                                                style: TextStyle(
                                                  color: Colors.green.shade800,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            IconButton(
                                              icon:
                                                  const Icon(Icons.more_vert),
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
                          "Showing ${filteredCustomers.length} of ${customers.length} entries",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text("Prev"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text("1"),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text("Next"),
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
    );
  }
}
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FieldsPage extends StatefulWidget {
  final String token;

  const FieldsPage({
    super.key,
    required this.token,
  });

  @override
  State<FieldsPage> createState() => _FieldsPageState();
}

class _FieldsPageState extends State<FieldsPage> {
  List fields = [];

  final nameController = TextEditingController();

  Future<void> fetchFields() async {
    final response = await http.get(
      Uri.parse('http://localhost:4000/api/fields'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        fields = jsonDecode(response.body);
      });
    }
  }

  Future<void> createField() async {
    if (nameController.text.trim().isEmpty) return;

    await http.post(
      Uri.parse('http://localhost:4000/api/fields'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'name': nameController.text.trim(),
      }),
    );

    nameController.clear();
    fetchFields();
  }

  Future<void> updateField(int id, String name) async {
    await http.put(
      Uri.parse('http://localhost:4000/api/fields/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'name': name,
      }),
    );

    fetchFields();
  }

  Future<void> deleteField(int id) async {
    await http.delete(
      Uri.parse('http://localhost:4000/api/fields/$id'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    fetchFields();
  }

  void showEditDialog(Map field) {
    final editController = TextEditingController(
      text: field['name'],
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Field"),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(
              labelText: "Field Name",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                updateField(
                  field['id'],
                  editController.text,
                );
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Widget fieldStatusBadge(Map field) {
    final isActive = field['is_active'] == 1 ||
        field['is_active'] == true ||
        field['status'] == 'active' ||
        field['status'] == null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? "Active" : "Inactive",
        style: TextStyle(
          color: isActive ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget fieldCard(Map field) {
    final price = field['price_per_hour'] ?? 100000;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.shade50,
                  child: Icon(
                    Icons.stadium,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    field['name'] ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              field['description'] ?? 'No description',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            Text(
              "ລາຄາ: $price Kip/ຊົ່ວໂມງ",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            fieldStatusBadge(field),

            const Spacer(),

            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    showEditDialog(field);
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("Edit"),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    deleteField(field['id']);
                  },
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text("Delete"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchFields();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Field Management",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: fetchFields,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Field Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: createField,
                      icon: const Icon(Icons.add),
                      label: const Text("Add Field"),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: fields.isEmpty
                ? const Center(
                    child: Text("No fields found"),
                  )
                : GridView.builder(
                    itemCount: fields.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 420,
                      mainAxisExtent: 230,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                    ),
                    itemBuilder: (context, index) {
                      final field = fields[index];
                      return fieldCard(field);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
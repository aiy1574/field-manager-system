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

    print(response.body);

    if (response.statusCode == 200) {
      setState(() {
        fields = jsonDecode(response.body);
      });
    }
  }

  Future<void> createField() async {
    await http.post(
      Uri.parse('http://localhost:4000/api/fields'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'name': nameController.text,
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

  @override
  void initState() {
    super.initState();
    fetchFields();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Football Fields"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Field Name",
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: createField,
                  child: const Text("Add"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: fields.length,
                itemBuilder: (context, index) {
                  final field = fields[index];

                  return Card(
                    child: ListTile(
                      title: Text(field['name']),
                      subtitle: Text(
                        field['description'] ?? '',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              showEditDialog(field);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              deleteField(field['id']);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
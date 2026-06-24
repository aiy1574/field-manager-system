import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'theme.dart';

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
  bool loading = true;

  final nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchFields();
  }

  Future<void> fetchFields() async {
    setState(() {
      loading = true;
    });

    final response = await http.get(
      Uri.parse('http://localhost:4000/api/fields'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        fields = jsonDecode(response.body);
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> createField() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ກະລຸນາປ້ອນຊື່ສະໜາມ')),
      );
      return;
    }

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
    if (name.trim().isEmpty) return;

    await http.put(
      Uri.parse('http://localhost:4000/api/fields/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'name': name.trim(),
      }),
    );

    fetchFields();
  }

  Future<void> deleteField(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ຢືນຢັນການລຶບ'),
        content: const Text('ຕ້ອງການລຶບສະໜາມນີ້ບໍ?'),
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
            child: const Text('ລຶບ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

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
      text: field['name'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ແກ້ໄຂສະໜາມ'),
          content: TextField(
            controller: editController,
            decoration: InputDecoration(
              labelText: 'ຊື່ສະໜາມ',
              prefixIcon: const Icon(Icons.stadium),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('ຍົກເລີກ'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                updateField(
                  field['id'],
                  editController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('ບັນທຶກ'),
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
        isActive ? 'ພ້ອມໃຊ້ງານ' : 'ບໍ່ພ້ອມໃຊ້ງານ',
        style: TextStyle(
          color: isActive ? primaryGreen : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget fieldCard(Map field) {
    final price = field['price_per_hour'] ?? 100000;

    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.shade50,
                  child: const Icon(
                    Icons.stadium,
                    color: primaryGreen,
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
              field['description'] ?? 'ບໍ່ມີລາຍລະອຽດ',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ລາຄາ: $price ກີບ/ຊົ່ວໂມງ',
              style: const TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            fieldStatusBadge(field),
            const Spacer(),
            Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryGreen,
                    side: const BorderSide(color: primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    showEditDialog(field);
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('ແກ້ໄຂ'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    deleteField(field['id']);
                  },
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('ລຶບ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget addFieldCard() {
    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'ຊື່ສະໜາມ',
                  hintText: 'ເຊັ່ນ: ເດີ່ນ 1',
                  prefixIcon: const Icon(Icons.stadium, color: primaryGreen),
                  filled: true,
                  fillColor: lightBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: primaryGreen,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: createField,
                icon: const Icon(Icons.add),
                label: const Text(
                  'ເພີ່ມສະໜາມ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'ຈັດການສະໜາມ',
                  style: TextStyle(
                    fontSize: 28,
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
                  onPressed: fetchFields,
                  icon: const Icon(Icons.refresh),
                  label: const Text('ໂຫຼດຄືນ'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            addFieldCard(),
            const SizedBox(height: 20),
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: primaryGreen,
                      ),
                    )
                  : fields.isEmpty
                      ? const Center(
                          child: Text('ບໍ່ພົບຂໍ້ມູນສະໜາມ'),
                        )
                      : GridView.builder(
                          itemCount: fields.length,
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 420,
                            mainAxisExtent: 240,
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
      ),
    );
  }
}
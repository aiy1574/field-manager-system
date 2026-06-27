import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../theme.dart';

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
  final String baseUrl = 'http://localhost:4000/api';

  List fields = [];
  bool loading = true;

  final nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchFields();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Map<String, String> get authHeaders {
    return {
      'Authorization': 'Bearer ${widget.token}',
    };
  }

  Map<String, String> get jsonHeaders {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${widget.token}',
    };
  }

  Future<void> fetchFields() async {
    setState(() {
      loading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fields'),
        headers: authHeaders,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          fields = jsonDecode(response.body);
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ໂຫຼດຂໍ້ມູນສະໜາມບໍ່ສຳເລັດ: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ເຊື່ອມຕໍ່ server ບໍ່ໄດ້: $e')),
      );
    }
  }

  Future<void> createField() async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ກະລຸນາປ້ອນຊື່ສະໜາມ')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fields'),
        headers: jsonHeaders,
        body: jsonEncode({
          'name': name,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        nameController.clear();
        fetchFields();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ເພີ່ມສະໜາມສຳເລັດ')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ເພີ່ມສະໜາມບໍ່ສຳເລັດ: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ເພີ່ມສະໜາມຜິດພາດ: $e')),
      );
    }
  }

  Future<void> updateField(int id, String name) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ຊື່ສະໜາມຫ້າມວ່າງ')),
      );
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/fields/$id'),
        headers: jsonHeaders,
        body: jsonEncode({
          'name': cleanName,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        fetchFields();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ແກ້ໄຂສະໜາມສຳເລັດ')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ແກ້ໄຂບໍ່ສຳເລັດ: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ແກ້ໄຂຜິດພາດ: $e')),
      );
    }
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

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/fields/$id'),
        headers: authHeaders,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        fetchFields();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ລຶບສະໜາມສຳເລັດ')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ລຶບບໍ່ສຳເລັດ: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ລຶບຜິດພາດ: $e')),
      );
    }
  }

  String normalizeTime(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.length >= 5) {
      return text.substring(0, 5);
    }
    return text;
  }

  int parsePrice(String value) {
    final clean = value.replaceAll(',', '').replaceAll(' ', '').trim();
    return int.tryParse(clean) ?? 0;
  }

  List normalizeServiceList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map && decoded['data'] is List) return decoded['data'];
    if (decoded is Map && decoded['services'] is List)
      return decoded['services'];
    if (decoded is Map && decoded['rows'] is List) return decoded['rows'];
    return [];
  }

  Future<List> fetchFieldServices(int fieldId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/field-services?field_id=$fieldId'),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return normalizeServiceList(decoded);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ໂຫຼດລາຄາເດີ່ນບໍ່ສຳເລັດ: ${response.body}',
            ),
          ),
        );
      }

      return [];
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ໂຫຼດລາຄາເດີ່ນຜິດພາດ: $e')),
        );
      }

      return [];
    }
  }

  Map? findService(
    List services,
    String startTime,
    String endTime,
  ) {
    for (final item in services) {
      if (item is Map) {
        final start = normalizeTime(item['start_time']);
        final end = normalizeTime(item['end_time']);

        if (start == startTime && end == endTime) {
          return item;
        }
      }
    }

    return null;
  }

  Future<bool> upsertFieldService({
    required int fieldId,
    required String startTime,
    required String endTime,
    required int price,
    required Map? existingService,
  }) async {
    final body = {
      'field_id': fieldId,
      'service_name': '$startTime - $endTime',
      'start_time': startTime,
      'end_time': endTime,
      'price': price,
      'price_per_hour': price,
      'is_active': 1,
    };

    try {
      http.Response response;

      if (existingService != null && existingService['id'] != null) {
        response = await http.put(
          Uri.parse('$baseUrl/field-services/${existingService['id']}'),
          headers: jsonHeaders,
          body: jsonEncode(body),
        );
      } else {
        response = await http.post(
          Uri.parse('$baseUrl/field-services'),
          headers: jsonHeaders,
          body: jsonEncode(body),
        );
      }

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveFieldPrices({
    required int fieldId,
    required List services,
    required String price1700,
    required String price1800,
  }) async {
    final p1700 = parsePrice(price1700);
    final p1800 = parsePrice(price1800);

    if (p1700 <= 0 || p1800 <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ກະລຸນາປ້ອນລາຄາໃຫ້ຖືກຕ້ອງ')),
      );
      return;
    }

    final service1700 = findService(services, '17:00', '18:00');
    final service1800 = findService(services, '18:00', '24:00');

    final ok1 = await upsertFieldService(
      fieldId: fieldId,
      startTime: '17:00',
      endTime: '18:00',
      price: p1700,
      existingService: service1700,
    );

    final ok2 = await upsertFieldService(
      fieldId: fieldId,
      startTime: '18:00',
      endTime: '24:00',
      price: p1800,
      existingService: service1800,
    );

    if (!mounted) return;

    if (ok1 && ok2) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ບັນທຶກລາຄາເດີ່ນສຳເລັດ')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ບັນທຶກລາຄາບໍ່ສຳເລັດ: ກວດ backend field_service.routes.ts',
          ),
        ),
      );
    }
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
          content: SizedBox(
            width: 360,
            child: TextField(
              controller: editController,
              decoration: InputDecoration(
                labelText: 'ຊື່ສະໜາມ',
                prefixIcon: const Icon(Icons.stadium),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
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

  Future<void> showPriceDialog(Map field) async {
    final int fieldId = int.tryParse(field['id'].toString()) ?? 0;

    if (fieldId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ບໍ່ພົບ field_id')),
      );
      return;
    }

    final services = await fetchFieldServices(fieldId);

    final service1700 = findService(services, '17:00', '18:00');
    final service1800 = findService(services, '18:00', '24:00');

    final price1700Controller = TextEditingController(
      text: (service1700?['price'] ?? service1700?['price_per_hour'] ?? 500000)
          .toString(),
    );

    final price1800Controller = TextEditingController(
      text: (service1800?['price'] ?? service1800?['price_per_hour'] ?? 600000)
          .toString(),
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('ຈັດການລາຄາ: ${field['name'] ?? ''}'),
          content: SizedBox(
            width: 430,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                priceInputRow(
                  label: '17:00 - 18:00',
                  controller: price1700Controller,
                ),
                const SizedBox(height: 16),
                priceInputRow(
                  label: '18:00 - 24:00',
                  controller: price1800Controller,
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'ໝາຍເຫດ: ລາຄານີ້ຈະຖືກດຶງໄປໃຊ້ໃນ Customer App ຕອນລູກຄ້າເລືອກເວລາຈອງ.',
                    style: TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('ຍົກເລີກ'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                saveFieldPrices(
                  fieldId: fieldId,
                  services: services,
                  price1700: price1700Controller.text,
                  price1800: price1800Controller.text,
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('ບັນທຶກ'),
            ),
          ],
        );
      },
    );
  }

  Widget priceInputRow({
    required String label,
    required TextEditingController controller,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'ລາຄາ',
              suffixText: 'ກີບ',
              prefixIcon: const Icon(Icons.payments),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
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
            const Text(
              'ລາຄາເດີ່ນ: ກຳນົດຕາມ Time Slot',
              style: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            fieldStatusBadge(field),
            const Spacer(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    showPriceDialog(field);
                  },
                  icon: const Icon(Icons.payments, size: 18),
                  label: const Text('ລາຄາ'),
                ),
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
                  prefixIcon: const Icon(
                    Icons.stadium,
                    color: primaryGreen,
                  ),
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
                onSubmitted: (_) => createField(),
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
                            mainAxisExtent: 285,
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

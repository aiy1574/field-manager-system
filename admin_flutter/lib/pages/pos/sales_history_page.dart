import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const Color primaryGreen = Color(0xFF16A34A);
const Color lightBg = Color(0xFFF4F8F1);

class SalesHistoryPage extends StatefulWidget {
  final String token;

  const SalesHistoryPage({
    super.key,
    required this.token,
  });

  @override
  State<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage> {
  List sales = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchSales();
  }

  void showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : primaryGreen,
      ),
    );
  }

  String formatPrice(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;

    final text = number.toInt().toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );

    return '$text ກີບ';
  }

  String formatDateTime(dynamic value) {
    if (value == null) return '-';

    final text = value.toString();

    if (text.length >= 19) {
      return text.substring(0, 19);
    }

    return text;
  }

  String paymentText(dynamic value) {
    final text = value?.toString() ?? 'cash';

    switch (text) {
      case 'cash':
        return 'ເງິນສົດ';
      case 'transfer':
        return 'ໂອນເງິນ';
      case 'qr':
        return 'QR';
      default:
        return text;
    }
  }

  Future<void> fetchSales() async {
    setState(() {
      loading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:4000/api/sales'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          sales = jsonDecode(response.body);
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });

        showMessage('ໂຫຼດປະຫວັດການຂາຍບໍ່ສຳເລັດ', error: true);
      }
    } catch (e) {
      setState(() {
        loading = false;
      });

      showMessage('ເຊື່ອມຕໍ່ Server ບໍ່ໄດ້: $e', error: true);
    }
  }

  Future<void> showSaleDetail(int saleId) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:4000/api/sales/$saleId'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode != 200) {
        showMessage('ໂຫຼດລາຍລະອຽດບິນບໍ່ສຳເລັດ', error: true);
        return;
      }

      final data = jsonDecode(response.body);
      final sale = data['sale'];
      final items = data['items'] as List;

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Text(
              'ລາຍລະອຽດບິນ #$saleId',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 650,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Card(
                      color: lightBg,
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            summaryRow(
                              'ວັນທີຂາຍ',
                              formatDateTime(sale['created_at']),
                            ),
                            summaryRow(
                              'ວິທີຊຳລະ',
                              paymentText(sale['payment_method']),
                            ),
                            summaryRow(
                              'ຍອດລວມ',
                              formatPrice(sale['total']),
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'ລາຍການສິນຄ້າ',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        Colors.green.shade50,
                      ),
                      columns: const [
                        DataColumn(label: Text('ສິນຄ້າ')),
                        DataColumn(label: Text('ລາຄາ')),
                        DataColumn(label: Text('ຈຳນວນ')),
                        DataColumn(label: Text('ລວມ')),
                      ],
                      rows: items.map<DataRow>((item) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(item['product_name']?.toString() ?? '-'),
                            ),
                            DataCell(
                              Text(formatPrice(item['unit_price'])),
                            ),
                            DataCell(
                              Text(item['qty']?.toString() ?? '0'),
                            ),
                            DataCell(
                              Text(
                                formatPrice(item['subtotal']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ປິດ'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      showMessage('ມີຂໍ້ຜິດພາດ: $e', error: true);
    }
  }

  Widget summaryRow(String title, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: bold ? primaryGreen : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget totalSummaryCard() {
    double total = 0;

    for (final sale in sales) {
      total += double.tryParse(sale['total'].toString()) ?? 0;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.green.shade50,
              child: const Icon(
                Icons.payments,
                color: primaryGreen,
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'ຍອດຂາຍລວມ:',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              formatPrice(total),
              style: const TextStyle(
                color: primaryGreen,
                fontSize: 22,
                fontWeight: FontWeight.bold,
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
        padding: const EdgeInsets.all(34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'ປະຫວັດການຂາຍ',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: fetchSales,
                  icon: const Icon(Icons.refresh),
                  label: const Text('ໂຫຼດຄືນ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            totalSummaryCard(),
            const SizedBox(height: 18),
            Expanded(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: primaryGreen,
                        ),
                      )
                    : sales.isEmpty
                        ? const Center(
                            child: Text('ຍັງບໍ່ມີປະຫວັດການຂາຍ'),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 1000,
                              ),
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    Colors.green.shade50,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('ເລກບິນ')),
                                    DataColumn(label: Text('ວັນທີຂາຍ')),
                                    DataColumn(label: Text('ຍອດລວມ')),
                                    DataColumn(label: Text('ວິທີຊຳລະ')),
                                    DataColumn(label: Text('ພະນັກງານ')),
                                    DataColumn(label: Text('ຈັດການ')),
                                  ],
                                  rows: sales.map<DataRow>((sale) {
                                    final saleId = int.tryParse(
                                          sale['id'].toString(),
                                        ) ??
                                        0;

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            'SALE-${saleId.toString().padLeft(3, '0')}',
                                            style: const TextStyle(
                                              color: primaryGreen,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(formatDateTime(
                                              sale['created_at'])),
                                        ),
                                        DataCell(
                                          Text(
                                            formatPrice(sale['total']),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(paymentText(
                                              sale['payment_method'])),
                                        ),
                                        DataCell(
                                          Text(
                                            sale['sold_by_name']?.toString() ??
                                                sale['sold_by']?.toString() ??
                                                '-',
                                          ),
                                        ),
                                        DataCell(
                                          TextButton.icon(
                                            onPressed: () {
                                              showSaleDetail(saleId);
                                            },
                                            icon: const Icon(Icons.visibility),
                                            label: const Text('ເບິ່ງ'),
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
            ),
          ],
        ),
      ),
    );
  }
}

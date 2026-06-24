import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'theme.dart';

class ProductsPage extends StatefulWidget {
  final String token;

  const ProductsPage({
    super.key,
    required this.token,
  });

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List products = [];
  List filteredProducts = [];
  bool loading = true;

  final searchController = TextEditingController();
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  void dispose() {
    searchController.dispose();
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    super.dispose();
  }

  void showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : primaryGreen,
      ),
    );
  }

  int parseId(dynamic value) {
    return int.tryParse(value.toString()) ?? 0;
  }

  String formatPrice(dynamic value) {
    final price = double.tryParse(value.toString()) ?? 0;

    String text;
    if (price == price.roundToDouble()) {
      text = price.toInt().toString();
    } else {
      text = price.toStringAsFixed(2);
    }

    text = text.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    return '$text Kip';
  }

  Future<void> fetchProducts() async {
    setState(() {
      loading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:4000/api/products'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          products = data;
          filteredProducts = data;
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });

        showMessage('ບໍ່ສາມາດໂຫຼດຂໍ້ມູນສິນຄ້າໄດ້', error: true);
      }
    } catch (e) {
      setState(() {
        loading = false;
      });

      showMessage('ເຊື່ອມຕໍ່ Server ບໍ່ໄດ້', error: true);
    }
  }

  void searchProducts(String value) {
    final keyword = value.toLowerCase();

    setState(() {
      filteredProducts = products.where((product) {
        final name = (product['name'] ?? '').toString().toLowerCase();
        final price = (product['price'] ?? '').toString().toLowerCase();
        final stock = (product['stock'] ?? '').toString().toLowerCase();

        return name.contains(keyword) ||
            price.contains(keyword) ||
            stock.contains(keyword);
      }).toList();
    });
  }

  Future<void> createProduct() async {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text.trim()) ?? 0;
    final stock = int.tryParse(stockController.text.trim()) ?? 0;

    if (name.isEmpty) {
      showMessage('ກະລຸນາປ້ອນຊື່ສິນຄ້າ', error: true);
      return;
    }

    if (price <= 0) {
      showMessage('ກະລຸນາປ້ອນລາຄາໃຫ້ຖືກຕ້ອງ', error: true);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:4000/api/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'name': name,
          'price': price,
          'stock': stock,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        nameController.clear();
        priceController.clear();
        stockController.clear();

        await fetchProducts();
        showMessage('ເພີ່ມສິນຄ້າສຳເລັດ');
      } else {
        showMessage('ເພີ່ມສິນຄ້າບໍ່ສຳເລັດ', error: true);
      }
    } catch (e) {
      showMessage('ເຊື່ອມຕໍ່ Server ບໍ່ໄດ້', error: true);
    }
  }

  Future<void> updateProduct(
    int id,
    String name,
    double price,
    int stock,
  ) async {
    if (id == 0) {
      showMessage('ບໍ່ພົບ ID ສິນຄ້າ', error: true);
      return;
    }

    if (name.trim().isEmpty) {
      showMessage('ກະລຸນາປ້ອນຊື່ສິນຄ້າ', error: true);
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('http://localhost:4000/api/products/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'name': name,
          'price': price,
          'stock': stock,
        }),
      );

      if (response.statusCode == 200) {
        await fetchProducts();
        showMessage('ແກ້ໄຂສິນຄ້າສຳເລັດ');
      } else {
        showMessage('ແກ້ໄຂສິນຄ້າບໍ່ສຳເລັດ', error: true);
      }
    } catch (e) {
      showMessage('ເຊື່ອມຕໍ່ Server ບໍ່ໄດ້', error: true);
    }
  }

  Future<void> deleteProduct(int id) async {
    if (id == 0) {
      showMessage('ບໍ່ພົບ ID ສິນຄ້າ', error: true);
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('http://localhost:4000/api/products/$id'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        await fetchProducts();
        showMessage('ລຶບສິນຄ້າສຳເລັດ');
      } else {
        showMessage('ລຶບສິນຄ້າບໍ່ສຳເລັດ', error: true);
      }
    } catch (e) {
      showMessage('ເຊື່ອມຕໍ່ Server ບໍ່ໄດ້', error: true);
    }
  }

  void showEditDialog(Map product) {
    final editNameController = TextEditingController(
      text: product['name']?.toString() ?? '',
    );

    final editPriceController = TextEditingController(
      text: product['price']?.toString() ?? '0',
    );

    final editStockController = TextEditingController(
      text: product['stock']?.toString() ?? '0',
    );

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'ແກ້ໄຂສິນຄ້າ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: editNameController,
                  decoration: InputDecoration(
                    labelText: 'ຊື່ສິນຄ້າ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: primaryGreen,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: editPriceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'ລາຄາ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: primaryGreen,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: editStockController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'ຈຳນວນ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: primaryGreen,
                        width: 2,
                      ),
                    ),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await updateProduct(
                  parseId(product['id']),
                  editNameController.text.trim(),
                  double.tryParse(editPriceController.text.trim()) ?? 0,
                  int.tryParse(editStockController.text.trim()) ?? 0,
                );

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('ບັນທຶກ'),
            ),
          ],
        );
      },
    );
  }

  void confirmDelete(Map product) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'ລຶບສິນຄ້າ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'ຕ້ອງການລຶບ "${product['name']}" ແທ້ບໍ່?',
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
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await deleteProduct(parseId(product['id']));

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('ລຶບ'),
            ),
          ],
        );
      },
    );
  }

  Widget stockBadge(int stock) {
    final inStock = stock > 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: inStock ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        inStock ? 'ມີສິນຄ້າ' : 'ໝົດສິນຄ້າ',
        style: TextStyle(
          color: inStock ? primaryGreen : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget inputBox({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryGreen),
        filled: true,
        fillColor: lightBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: primaryGreen,
            width: 2,
          ),
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
                  'ຈັດການສິນຄ້າ',
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
                  onPressed: fetchProducts,
                  icon: const Icon(Icons.refresh),
                  label: const Text('ໂຫຼດຄືນ'),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Add product form
            Card(
              color: Colors.white,
              elevation: 3,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: inputBox(
                        controller: nameController,
                        label: 'ຊື່ສິນຄ້າ',
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(width: 15),
                    SizedBox(
                      width: 160,
                      child: inputBox(
                        controller: priceController,
                        label: 'ລາຄາ',
                        icon: Icons.payments_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    SizedBox(
                      width: 160,
                      child: inputBox(
                        controller: stockController,
                        label: 'ຈຳນວນ',
                        icon: Icons.warehouse_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: createProduct,
                        icon: const Icon(Icons.add),
                        label: const Text('ເພີ່ມສິນຄ້າ'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Product table
            Expanded(
              child: Card(
                color: Colors.white,
                elevation: 3,
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
                            width: 480,
                            child: TextField(
                              controller: searchController,
                              onChanged: searchProducts,
                              decoration: InputDecoration(
                                hintText: 'ຄົ້ນຫາສິນຄ້າ...',
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
                          const Spacer(),
                          Text(
                            'ທັງໝົດ ${filteredProducts.length} ລາຍການ',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
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
                          : filteredProducts.isEmpty
                              ? const Center(
                                  child: Text('ບໍ່ພົບຂໍ້ມູນສິນຄ້າ'),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minWidth: 900,
                                      ),
                                      child: DataTable(
                                        headingRowHeight: 58,
                                        dataRowMinHeight: 66,
                                        dataRowMaxHeight: 76,
                                        headingRowColor:
                                            MaterialStateProperty.all(
                                          Colors.green.shade50,
                                        ),
                                        columns: const [
                                          DataColumn(label: Text('ລະຫັດ')),
                                          DataColumn(
                                            label: Text('ຊື່ສິນຄ້າ'),
                                          ),
                                          DataColumn(label: Text('ລາຄາ')),
                                          DataColumn(label: Text('ຈຳນວນ')),
                                          DataColumn(label: Text('ສະຖານະ')),
                                          DataColumn(label: Text('ຈັດການ')),
                                        ],
                                        rows: filteredProducts.map((product) {
                                          final id = product['id'] ?? '-';
                                          final name = product['name'] ?? '-';
                                          final stock = int.tryParse(
                                                product['stock'].toString(),
                                              ) ??
                                              0;

                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Text(
                                                  'PRO-${id.toString().padLeft(3, '0')}',
                                                  style: const TextStyle(
                                                    color: primaryGreen,
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
                                                Text(
                                                  formatPrice(product['price']),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(stock.toString()),
                                              ),
                                              DataCell(stockBadge(stock)),
                                              DataCell(
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      tooltip: 'ແກ້ໄຂ',
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        color: primaryGreen,
                                                      ),
                                                      onPressed: () {
                                                        showEditDialog(product);
                                                      },
                                                    ),
                                                    IconButton(
                                                      tooltip: 'ລຶບ',
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed: () {
                                                        confirmDelete(product);
                                                      },
                                                    ),
                                                  ],
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
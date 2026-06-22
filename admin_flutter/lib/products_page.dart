import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();

  Future<void> fetchProducts() async {
    final response = await http.get(
      Uri.parse('http://localhost:4000/api/products'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        products = jsonDecode(response.body);
      });
    }
  }

  Future<void> createProduct() async {
    if (nameController.text.trim().isEmpty) return;

    await http.post(
      Uri.parse('http://localhost:4000/api/products'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'name': nameController.text.trim(),
        'price': double.tryParse(priceController.text) ?? 0,
        'stock': int.tryParse(stockController.text) ?? 0,
      }),
    );

    nameController.clear();
    priceController.clear();
    stockController.clear();

    fetchProducts();
  }

  Future<void> updateProduct(
    int id,
    String name,
    double price,
    int stock,
  ) async {
    await http.put(
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

    fetchProducts();
  }

  Future<void> deleteProduct(int id) async {
    await http.delete(
      Uri.parse('http://localhost:4000/api/products/$id'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    fetchProducts();
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
          title: const Text('Edit Product'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: editNameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: editPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: editStockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock',
                    border: OutlineInputBorder(),
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await updateProduct(
                  product['id'],
                  editNameController.text.trim(),
                  double.tryParse(editPriceController.text) ?? 0,
                  int.tryParse(editStockController.text) ?? 0,
                );

                Navigator.pop(context);
              },
              child: const Text('Save'),
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
          title: const Text('Delete Product'),
          content: Text(
            'Do you want to delete "${product['name']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await deleteProduct(product['id']);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget stockBadge(int stock) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: stock > 0 ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        stock > 0 ? 'In Stock' : 'Out Stock',
        style: TextStyle(
          color: stock > 0 ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Product Management',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: fetchProducts,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: createProduct,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Product'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 300,
                  ),
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Product Name')),
                      DataColumn(label: Text('Price')),
                      DataColumn(label: Text('Stock')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: products.map((product) {
                      final stock = int.tryParse(
                            product['stock'].toString(),
                          ) ??
                          0;

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(product['id'].toString()),
                          ),
                          DataCell(
                            Text(product['name'] ?? '-'),
                          ),
                          DataCell(
                            Text('${product['price']} Kip'),
                          ),
                          DataCell(
                            Text(stock.toString()),
                          ),
                          DataCell(
                            stockBadge(stock),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    showEditDialog(product);
                                  },
                                ),
                                IconButton(
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
    );
  }
}

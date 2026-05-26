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
  State<ProductsPage> createState() =>
      _ProductsPageState();
}

class _ProductsPageState
    extends State<ProductsPage> {
  List products = [];

  final nameController =
      TextEditingController();

  final priceController =
      TextEditingController();

  final stockController =
      TextEditingController();

  Future<void> fetchProducts() async {
    final response = await http.get(
      Uri.parse(
        'http://localhost:4000/api/products',
      ),
      headers: {
        'Authorization':
            'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        products = jsonDecode(response.body);
      });
    }
  }

  Future<void> createProduct() async {
    await http.post(
      Uri.parse(
        'http://localhost:4000/api/products',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'name': nameController.text,
        'price':
            double.tryParse(
                  priceController.text,
                ) ??
                0,
        'stock':
            int.tryParse(
                  stockController.text,
                ) ??
                0,
      }),
    );

    nameController.clear();
    priceController.clear();
    stockController.clear();

    fetchProducts();
  }

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Manage Products",
        ),
        actions: [
          IconButton(
            onPressed: fetchProducts,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller:
                          nameController,
                      decoration:
                          const InputDecoration(
                        labelText:
                            "Product Name",
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    TextField(
                      controller:
                          priceController,
                      decoration:
                          const InputDecoration(
                        labelText: "Price",
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    TextField(
                      controller:
                          stockController,
                      decoration:
                          const InputDecoration(
                        labelText: "Stock",
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            createProduct,
                        child: const Text(
                          "Add Product",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder:
                    (context, index) {
                  final product =
                      products[index];

                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.shopping_bag,
                      ),
                      title: Text(
                        product['name'],
                      ),
                      subtitle: Text(
                        'Price: ${product['price']} Kip\n'
                        'Stock: ${product['stock']}',
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
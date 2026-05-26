import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SellProductsPage extends StatefulWidget {
  final String token;

  const SellProductsPage({
    super.key,
    required this.token,
  });

  @override
  State<SellProductsPage> createState() => _SellProductsPageState();
}

class _SellProductsPageState extends State<SellProductsPage> {
  List products = [];
  List cart = [];

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

  void addToCart(Map product) {
    setState(() {
      final index = cart.indexWhere(
        (item) => item['product_id'] == product['id'],
      );

      if (index >= 0) {
        cart[index]['qty'] += 1;
      } else {
        cart.add({
          'product_id': product['id'],
          'name': product['name'],
          'price': double.tryParse(product['price'].toString()) ?? 0,
          'qty': 1,
        });
      }
    });
  }

  double get total {
    double sum = 0;
    for (final item in cart) {
      sum += item['price'] * item['qty'];
    }
    return sum;
  }

  Future<void> checkout() async {
    if (cart.isEmpty) return;

    final response = await http.post(
      Uri.parse('http://localhost:4000/api/sales'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'items': cart,
      }),
    );

    print(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        cart.clear();
      });

      fetchProducts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sale completed"),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.body),
        ),
      );
    }
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
        title: const Text("Sell Products"),
        actions: [
          IconButton(
            onPressed: fetchProducts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.shopping_bag),
                      title: Text(product['name']),
                      subtitle: Text(
                        'Price: ${product['price']} Kip\n'
                        'Stock: ${product['stock']}',
                      ),
                      trailing: ElevatedButton(
                        onPressed: product['stock'] <= 0
                            ? null
                            : () {
                                addToCart(product);
                              },
                        child: const Text("Add"),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          Container(
            width: 350,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Cart",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];

                      return ListTile(
                        title: Text(item['name']),
                        subtitle: Text(
                          '${item['qty']} x ${item['price']} Kip',
                        ),
                        trailing: Text(
                          '${item['qty'] * item['price']}',
                        ),
                      );
                    },
                  ),
                ),

                const Divider(),

                Text(
                  "Total: $total Kip",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: cart.isEmpty ? null : checkout,
                    child: const Text("Checkout"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
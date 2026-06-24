import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'theme.dart';

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
  List filteredProducts = [];
  List cart = [];

  bool loading = true;
  bool checkingOut = false;

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  void dispose() {
    searchController.dispose();
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

  int parseInt(dynamic value) {
    return int.tryParse(value.toString()) ?? 0;
  }

  double parseDouble(dynamic value) {
    return double.tryParse(value.toString()) ?? 0;
  }

  String formatPrice(dynamic value) {
    final price = parseDouble(value);

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

  double get total {
    double sum = 0;

    for (final item in cart) {
      final price = parseDouble(item['price']);
      final qty = parseInt(item['qty']);
      sum += price * qty;
    }

    return sum;
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

  void addToCart(Map product) {
    final productId = parseInt(product['id']);
    final productName = product['name']?.toString() ?? '-';
    final productPrice = parseDouble(product['price']);
    final productStock = parseInt(product['stock']);

    if (productStock <= 0) {
      showMessage('ສິນຄ້ານີ້ໝົດ Stock ແລ້ວ', error: true);
      return;
    }

    final index = cart.indexWhere(
      (item) => parseInt(item['product_id']) == productId,
    );

    if (index >= 0) {
      final currentQty = parseInt(cart[index]['qty']);

      if (currentQty >= productStock) {
        showMessage('ຈຳນວນສິນຄ້າບໍ່ພຽງພໍ', error: true);
        return;
      }

      setState(() {
        cart[index]['qty'] = currentQty + 1;
      });
    } else {
      setState(() {
        cart.add({
          'product_id': productId,
          'name': productName,
          'price': productPrice,
          'qty': 1,
          'stock': productStock,
        });
      });
    }
  }

  void increaseQty(int index) {
    final stock = parseInt(cart[index]['stock']);
    final qty = parseInt(cart[index]['qty']);

    if (qty >= stock) {
      showMessage('ຈຳນວນສິນຄ້າບໍ່ພຽງພໍ', error: true);
      return;
    }

    setState(() {
      cart[index]['qty'] = qty + 1;
    });
  }

  void decreaseQty(int index) {
    setState(() {
      final qty = parseInt(cart[index]['qty']);

      if (qty > 1) {
        cart[index]['qty'] = qty - 1;
      } else {
        cart.removeAt(index);
      }
    });
  }

  void removeFromCart(int index) {
    setState(() {
      cart.removeAt(index);
    });
  }

  Future<void> checkout() async {
    if (cart.isEmpty) {
      showMessage('ກະລຸນາເລືອກສິນຄ້າກ່ອນ', error: true);
      return;
    }

    final receiptItems = cart.map((item) {
      return {
        'product_id': parseInt(item['product_id']),
        'name': item['name'],
        'price': parseDouble(item['price']),
        'qty': parseInt(item['qty']),
      };
    }).toList();

    setState(() {
      checkingOut = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:4000/api/sales'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'items': receiptItems,
          'total_amount': total,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic responseData;

        try {
          responseData = jsonDecode(response.body);
        } catch (_) {
          responseData = null;
        }

        final totalBeforeClear = receiptItems.fold<double>(
          0,
          (sum, item) =>
              sum + parseDouble(item['price']) * parseInt(item['qty']),
        );

        setState(() {
          cart.clear();
          checkingOut = false;
        });

        await fetchProducts();

        showMessage('ຂາຍສິນຄ້າສຳເລັດ');

        if (mounted) {
          showReceiptDialog(
            items: receiptItems,
            totalAmount: totalBeforeClear,
            saleId: responseData is Map ? responseData['sale_id'] : null,
          );
        }
      } else {
        setState(() {
          checkingOut = false;
        });

        showMessage(
          response.body.isEmpty ? 'ຂາຍສິນຄ້າບໍ່ສຳເລັດ' : response.body,
          error: true,
        );
      }
    } catch (e) {
      setState(() {
        checkingOut = false;
      });

      showMessage('ເຊື່ອມຕໍ່ Server ບໍ່ໄດ້', error: true);
    }
  }

  void showReceiptDialog({
    required List items,
    required double totalAmount,
    dynamic saleId,
  }) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'ໃບບິນການຂາຍ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'ST Football Admin',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      saleId == null ? 'POS' : 'SALE-$saleId',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                ...items.map((item) {
                  final name = item['name'] ?? '-';
                  final price = parseDouble(item['price']);
                  final qty = parseInt(item['qty']);
                  final subtotal = price * qty;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '$name\n$qty x ${formatPrice(price)}',
                            style: const TextStyle(height: 1.4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          formatPrice(subtotal),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(),
                Row(
                  children: [
                    const Text(
                      'ລວມທັງໝົດ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatPrice(totalAmount),
                      style: const TextStyle(
                        fontSize: 20,
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('ປິດ'),
            ),
          ],
        );
      },
    );
  }

  Widget productCard(Map product) {
    final id = product['id'] ?? '-';
    final name = product['name'] ?? '-';
    final price = product['price'] ?? 0;
    final stock = parseInt(product['stock']);
    final inStock = stock > 0;

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: inStock ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.shopping_bag_outlined,
            color: inStock ? primaryGreen : Colors.red,
          ),
        ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            'ລະຫັດ: PRO-${id.toString().padLeft(3, '0')}\n'
            'ລາຄາ: ${formatPrice(price)} | ຄົງເຫຼືອ: $stock',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: inStock ? primaryGreen : Colors.grey,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: inStock
              ? () {
                  addToCart(product);
                }
              : null,
          icon: const Icon(Icons.add_shopping_cart, size: 18),
          label: const Text('ເພີ່ມ'),
        ),
      ),
    );
  }

  Widget cartItemCard(int index) {
    final item = cart[index];
    final name = item['name'] ?? '-';
    final price = parseDouble(item['price']);
    final qty = parseInt(item['qty']);
    final subtotal = price * qty;

    return Card(
      elevation: 1,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${formatPrice(price)} x $qty',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    decreaseQty(index);
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                  color: primaryGreen,
                ),
                Text(
                  qty.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    increaseQty(index);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  color: primaryGreen,
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    formatPrice(subtotal),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    removeFromCart(index);
                  },
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget emptyCart() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          const Text(
            'ຍັງບໍ່ມີສິນຄ້າໃນກະຕ່າ',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget searchHeader() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
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
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'ສິນຄ້າ ${filteredProducts.length} ລາຍການ',
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget cartHeader() {
    return Row(
      children: [
        const Icon(
          Icons.shopping_cart_outlined,
          color: primaryGreen,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'ກະຕ່າສິນຄ້າ',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (cart.isNotEmpty)
          TextButton.icon(
            onPressed: () {
              setState(() {
                cart.clear();
              });
            },
            icon: const Icon(Icons.clear),
            label: const Text('ລ້າງ'),
          ),
      ],
    );
  }

  Widget totalSection() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'ລວມທັງໝົດ',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          formatPrice(total),
          style: const TextStyle(
            fontSize: 24,
            color: primaryGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
                    'ຂາຍສິນຄ້າ',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Card(
                      elevation: 3,
                      shadowColor: Colors.black12,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          searchHeader(),
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
                                        child: Text(
                                          'ບໍ່ພົບຂໍ້ມູນສິນຄ້າ',
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(16),
                                        itemCount: filteredProducts.length,
                                        itemBuilder: (context, index) {
                                          return productCard(
                                            filteredProducts[index],
                                          );
                                        },
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    flex: 2,
                    child: Card(
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
                            cartHeader(),
                            const SizedBox(height: 18),
                            Expanded(
                              child: cart.isEmpty
                                  ? emptyCart()
                                  : ListView.builder(
                                      itemCount: cart.length,
                                      itemBuilder: (context, index) {
                                        return cartItemCard(index);
                                      },
                                    ),
                            ),
                            const Divider(),
                            totalSection(),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      Colors.grey.shade300,
                                  disabledForegroundColor: Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: cart.isEmpty || checkingOut
                                    ? null
                                    : checkout,
                                icon: checkingOut
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.payments_outlined),
                                label: Text(
                                  checkingOut
                                      ? 'ກຳລັງບັນທຶກ...'
                                      : 'ຊຳລະເງິນ / Checkout',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
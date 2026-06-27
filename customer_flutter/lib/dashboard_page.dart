import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'change_password_page.dart';
import 'booking_page.dart';
import 'edit_profile_page.dart';

const Color primaryGreen = Color(0xFF16A34A);
const Color lightBg = Color(0xFFF4F8F1);

class DashboardPage extends StatefulWidget {
  final String token;
  final Map customer;

  const DashboardPage({
    super.key,
    required this.token,
    required this.customer,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(token: widget.token, customer: widget.customer),
      BookingHistoryPage(token: widget.token, customer: widget.customer),
      ProfilePage(
        customer: widget.customer,
        token: widget.token,
      ),
    ];

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: const Text(
          "ລະບົບຈອງສະໜາມ ST",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: currentIndex,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "ໜ້າຫຼັກ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "ປະຫວັດ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "ໂປຣໄຟລ໌",
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String token;
  final Map customer;

  const HomePage({
    super.key,
    required this.token,
    required this.customer,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List fields = [];
  List filteredFields = [];
  bool loading = true;

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadFields();
  }

  Future<void> loadFields() async {
    final response = await http.get(
      Uri.parse('http://localhost:4000/api/fields'),
    );

    if (response.statusCode == 200) {
      setState(() {
        fields = jsonDecode(response.body);
        filteredFields = fields;
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  void searchField(String value) {
    setState(() {
      filteredFields = fields.where((field) {
        final name = (field['name'] ?? '').toString().toLowerCase();
        final desc = (field['description'] ?? '').toString().toLowerCase();
        final keyword = value.toLowerCase();

        return name.contains(keyword) || desc.contains(keyword);
      }).toList();
    });
  }

  String getPrice(Map field) {
    final price = field['price_per_hour'];

    if (price == null) {
      return "ລາຄາຕາມຊ່ວງເວລາ";
    }

    return "$price ກີບ/ຊົ່ວໂມງ";
  }

  Widget fieldCard(Map field) {
    final isActive = field['is_active'] == 1 ||
        field['is_active'] == true ||
        field['status'] == 'active' ||
        field['status'] == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 3,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.sports_soccer,
                  color: primaryGreen,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field['name'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      field['description'] ?? 'ສະໜາມຫຍ້າທຽມ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      getPrice(field),
                      style: const TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      isActive ? "ວ່າງ" : "ໃຊ້ງານ",
                      style: TextStyle(
                        color: isActive
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 88,
                    height: 38,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: isActive
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingPage(
                                    token: widget.token,
                                    customer: widget.customer,
                                    field: field,
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: const Text(
                        "ຈອງ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerName = widget.customer['full_name'] ?? '';

    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryGreen),
      );
    }

    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: loadFields,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ສະບາຍດີ",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        customerName.toString().isEmpty
                            ? "ລູກຄ້າ"
                            : customerName.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: searchController,
            onChanged: searchField,
            decoration: InputDecoration(
              hintText: "ຄົ້ນຫາສະໜາມ...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            "ເລືອກສະໜາມ",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          if (filteredFields.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text("ບໍ່ພົບສະໜາມ"),
              ),
            )
          else
            ...filteredFields.map((field) {
              return fieldCard(field);
            }),
        ],
      ),
    );
  }
}

class BookingHistoryPage extends StatefulWidget {
  final String token;
  final Map customer;

  const BookingHistoryPage({
    super.key,
    required this.token,
    required this.customer,
  });

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  List bookings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    final response = await http.get(
      Uri.parse('http://localhost:4000/api/bookings'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final allBookings = jsonDecode(response.body);

      setState(() {
        bookings = allBookings
            .where(
              (b) => b['customer_id'] == widget.customer['id'],
            )
            .toList();

        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> requestCancel(int bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text(
          "ຂໍຍົກເລີກການຈອງ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "ເຈົ້າຕ້ອງການສົ່ງຄຳຂໍຍົກເລີກການຈອງນີ້ໃຫ້ Admin ບໍ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ບໍ່"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("ຕົກລົງ"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await http.patch(
      Uri.parse('http://localhost:4000/api/bookings/$bookingId/cancel-request'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      fetchBookings();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ສົ່ງຄຳຂໍຍົກເລີກໃຫ້ Admin ແລ້ວ'),
        ),
      );
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.body)),
      );
    }
  }

  Color statusColor(String? status, String? paymentStatus) {
    if (status == 'checked_in') return Colors.green;
    if (status == 'cancelled') return Colors.red;
    if (status == 'cancel_requested') return Colors.deepOrange;
    if (paymentStatus == 'paid') return Colors.blue;
    if (paymentStatus == 'rejected') return Colors.red;
    return Colors.orange;
  }

  Color statusBgColor(String? status, String? paymentStatus) {
    if (status == 'checked_in') return Colors.green.shade50;
    if (status == 'cancelled') return Colors.red.shade50;
    if (status == 'cancel_requested') return Colors.orange.shade50;
    if (paymentStatus == 'paid') return Colors.blue.shade50;
    if (paymentStatus == 'rejected') return Colors.red.shade50;
    return Colors.orange.shade50;
  }

  String statusText(String? status, String? paymentStatus) {
    if (status == 'checked_in') return "ເຂົ້າໃຊ້ແລ້ວ";
    if (status == 'cancelled') return "ຍົກເລີກ";
    if (status == 'cancel_requested') return "ລໍຖ້າ Admin ອະນຸມັດຍົກເລີກ";

    if (paymentStatus == 'paid') return "ຊຳລະແລ້ວ";
    if (paymentStatus == 'rejected') return "ສະລິບຖືກປະຕິເສດ";

    return "ລໍຖ້າກວດສອບສະລິບ";
  }

  String formatDate(dynamic value) {
    if (value == null) return "-";
    final text = value.toString();
    if (text.length >= 10) return text.substring(0, 10);
    return text;
  }

  String formatTime(dynamic value) {
    if (value == null) return "-";
    final text = value.toString();
    if (text.length >= 5) return text.substring(0, 5);
    return text;
  }

  bool canRequestCancel(Map booking) {
    final status = booking['status']?.toString();
    if (status == 'cancelled') return false;
    if (status == 'cancel_requested') return false;
    if (status == 'checked_in') return false;
    return true;
  }

  Widget bookingCard(Map booking) {
    final status = booking['status']?.toString();
    final paymentStatus = booking['payment_status']?.toString();

    final color = statusColor(status, paymentStatus);
    final bookingId = booking['id'] ?? 0;

    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'BK-${bookingId.toString().padLeft(3, '0')}',
                  style: const TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor(status, paymentStatus),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    statusText(status, paymentStatus),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              booking['field_name'] ?? '',
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  formatDate(booking['booking_date']),
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(width: 18),
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  "${formatTime(booking['start_time'])} - ${formatTime(booking['end_time'])}",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  "ລາຄາລວມ",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  "${booking['total_price'] ?? 0} ກີບ",
                  style: const TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            if (canRequestCancel(booking)) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text(
                    "ຂໍຍົກເລີກການຈອງ",
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {
                    requestCancel(booking['id']);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryGreen),
      );
    }

    if (bookings.isEmpty) {
      return const Center(
        child: Text('ຍັງບໍ່ມີປະຫວັດການຈອງ'),
      );
    }

    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: fetchBookings,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            "ການຈອງຂອງຂ້ອຍ",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          ...bookings.map((booking) {
            return bookingCard(booking);
          }),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final Map customer;
  final String token;

  const ProfilePage({
    super.key,
    required this.customer,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          "ໂປຣໄຟລ໌",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),
        Card(
          elevation: 3,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 95,
                  height: 95,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 58,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  customer['full_name'] ?? '',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  customer['phone'] ?? '',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                profileItem(
                  icon: Icons.person,
                  title: "ຊື່",
                  value: customer['full_name'] ?? '-',
                ),
                profileItem(
                  icon: Icons.phone,
                  title: "ເບີໂທ",
                  value: customer['phone'] ?? '-',
                ),
                profileItem(
                  icon: Icons.email,
                  title: "ອີເມວ",
                  value: customer['email'] ?? '-',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: primaryGreen),
                title: const Text("ແກ້ໄຂຂໍ້ມູນ"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfilePage(
                        token: token,
                        customer: customer,
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock, color: primaryGreen),
                title: const Text("ປ່ຽນລະຫັດຜ່ານ"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangePasswordPage(
                        token: token,
                        customer: customer,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget profileItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryGreen),
          const SizedBox(width: 14),
          Text(
            "$title:",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

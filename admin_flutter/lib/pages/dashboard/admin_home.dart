import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../booking/bookings_page.dart';
import '../booking/create_booking_page.dart';
import '../booking/payment_approval_page.dart';

import '../manage/customers_page.dart';
import '../manage/fields_page.dart';
import '../manage/products_page.dart';

import '../pos/sell_products_page.dart';
import '../pos/sales_history_page.dart';

import '../reports/reports_page.dart';

const Color primaryGreen = Color(0xFF16A34A);
const Color darkGreen = Color(0xFF0F8A43);
const Color lightBg = Color(0xFFF4F8F1);
const Color softCard = Color(0xFFFFFFFF);

class AdminHomePage extends StatefulWidget {
  final String token;
  final String role;

  const AdminHomePage({
    super.key,
    required this.token,
    required this.role,
  });

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  String selectedPage = 'dashboard';
  Map<String, dynamic> dashboard = {};

  bool get isOwner {
    final role = widget.role.toLowerCase().trim();
    return role == 'owner' || role == 'admin';
  }

  String get roleText => isOwner ? 'Owner/Admin' : 'Staff';

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:4000/api/dashboard'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          dashboard = jsonDecode(response.body);
        });
      }
    } catch (_) {}
  }

  void openPage(String page) {
    setState(() {
      selectedPage = page;
    });
  }

  Widget roleBadge() {
    final owner = isOwner;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: owner ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: owner ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Text(
        roleText,
        style: TextStyle(
          color: owner ? primaryGreen : Colors.deepOrange,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget sidebarItem({
    required String title,
    required IconData icon,
    required String page,
    List<String> activePages = const [],
  }) {
    final selected = selectedPage == page || activePages.contains(selectedPage);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: ListTile(
        selected: selected,
        selectedTileColor: Colors.green.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        leading: Icon(
          icon,
          color: selected ? primaryGreen : Colors.black54,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? primaryGreen : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: () => openPage(page),
      ),
    );
  }

  Widget pageWrapper({
    required Widget child,
  }) {
    return Container(
      color: lightBg,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: child,
        ),
      ),
    );
  }

  Widget pageHeader({
    required String title,
    required IconData icon,
    String? subtitle,
    List<Widget>? actions,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            icon,
            color: darkGreen,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actions != null) ...actions,
      ],
    );
  }

  Widget introCard({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.green.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.green.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: darkGreen,
                size: 32,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      height: 1.5,
                      color: Colors.grey.shade700,
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

  Widget summaryCard(
    String title,
    String value,
    IconData icon, {
    String? unit,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: softCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: darkGreen,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (unit != null)
                    Text(
                      unit,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
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

  int dashboardColumns(double width) {
    if (width >= 1050) return 4;
    if (width >= 650) return 2;
    return 1;
  }

  Widget dashboardPage() {
    final todayBookings = dashboard['today_bookings']?.toString() ?? '0';
    final todayRevenue = dashboard['today_revenue']?.toString() ?? '0.00';
    final pendingPayments = dashboard['pending_payments']?.toString() ?? '0';
    final checkedIn = dashboard['checked_in']?.toString() ?? '0';

    return pageWrapper(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = dashboardColumns(constraints.maxWidth);

          return ListView(
            padding: const EdgeInsets.all(28),
            children: [
              pageHeader(
                title: 'ໜ້າຫຼັກ',
                icon: Icons.dashboard,
                subtitle: 'ພາບລວມຂອງລະບົບຈອງສະໜາມ ST',
                actions: [
                  roleBadge(),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: fetchDashboard,
                    icon: const Icon(Icons.refresh),
                    label: const Text('ໂຫຼດຄືນ'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              introCard(
                title: 'ຍິນດີຕ້ອນຮັບເຂົ້າສູ່ ST Football Admin',
                description:
                    'ໜ້ານີ້ໃຊ້ສຳລັບຕິດຕາມການຈອງ, ການຊຳລະ, ການເຂົ້າໃຊ້ສະໜາມ ແລະ ລາຍຮັບຂອງຮ້ານ.',
                icon: Icons.sports_soccer,
              ),
              const SizedBox(height: 22),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: columns,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: columns == 4 ? 1.55 : 2.35,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  summaryCard(
                    'ການຈອງມື້ນີ້',
                    todayBookings,
                    Icons.calendar_month,
                  ),
                  summaryCard(
                    'ລາຍຮັບ',
                    todayRevenue,
                    Icons.payments,
                    unit: 'ກີບ',
                  ),
                  summaryCard(
                    'ລໍຖ້າກວດສອບ',
                    pendingPayments,
                    Icons.hourglass_top,
                  ),
                  summaryCard(
                    'ເຂົ້າໃຊ້ແລ້ວ',
                    checkedIn,
                    Icons.login,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  int calculateModuleColumns(double width, int itemCount) {
    if (width >= 760) return 2;
    return 1;
  }

  Widget moduleCard(ModuleItem item, double width) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => openPage(item.page),
      child: Container(
        width: width,
        constraints: const BoxConstraints(
          minHeight: 235,
        ),
        decoration: BoxDecoration(
          color: softCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.green.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  item.icon,
                  color: darkGreen,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.4,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'ເຂົ້າໃຊ້ງານ',
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: primaryGreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget modulePage({
    required String title,
    required String subtitle,
    required IconData icon,
    required String introTitle,
    required String introDescription,
    required List<ModuleItem> items,
  }) {
    return pageWrapper(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth =
              constraints.maxWidth > 820 ? 820.0 : constraints.maxWidth;

          final columns = calculateModuleColumns(contentWidth, items.length);
          const spacing = 18.0;

          final itemWidth =
              (contentWidth - ((columns - 1) * spacing)) / columns;

          return ListView(
            padding: const EdgeInsets.all(28),
            children: [
              SizedBox(
                width: contentWidth,
                child: pageHeader(
                  title: title,
                  icon: icon,
                  subtitle: subtitle,
                  actions: [
                    roleBadge(),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: contentWidth,
                child: introCard(
                  title: introTitle,
                  description: introDescription,
                  icon: icon,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: contentWidth,
                child: Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children:
                      items.map((item) => moduleCard(item, itemWidth)).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget manageMenuPage() {
    if (!isOwner) return noPermissionPage();

    return modulePage(
      title: 'ຈັດການ',
      subtitle: 'ຈັດການຂໍ້ມູນພື້ນຖານພາຍໃນລະບົບ',
      icon: Icons.folder_copy,
      introTitle: 'ໜ້າຈັດການຂໍ້ມູນ',
      introDescription:
          'ເລືອກເມນູຍ່ອຍສຳລັບຈັດການພະນັກງານ, ລູກຄ້າ, ສະໜາມ ແລະ ສິນຄ້າ. ຂໍ້ມູນບາງສ່ວນໃຊ້ສຳລັບການຈອງ ແລະ POS.',
      items: [
        ModuleItem(
          title: 'ພະນັກງານ',
          subtitle: 'ຈັດການຜູ້ໃຊ້ Owner / Staff',
          icon: Icons.badge,
          page: 'employees',
        ),
        ModuleItem(
          title: 'ລູກຄ້າ',
          subtitle: 'ຈັດການຂໍ້ມູນລູກຄ້າທີ່ລົງທະບຽນ',
          icon: Icons.people,
          page: 'customers',
        ),
        ModuleItem(
          title: 'ສະໜາມ',
          subtitle: 'ຂໍ້ມູນສະໜາມ ແລະ ລາຄາເດີ່ນ',
          icon: Icons.stadium,
          page: 'fields',
        ),
        ModuleItem(
          title: 'ສິນຄ້າ',
          subtitle: 'ຈັດການສິນຄ້າ ແລະ stock',
          icon: Icons.shopping_cart,
          page: 'products',
        ),
      ],
    );
  }

  Widget bookingMenuPage() {
    return modulePage(
      title: 'ການຈອງ',
      subtitle: 'ຈັດການຂັ້ນຕອນການຈອງທັງໝົດ',
      icon: Icons.calendar_month,
      introTitle: 'ໜ້າຈັດການການຈອງ',
      introDescription:
          'ໃຊ້ສຳລັບສ້າງການຈອງ, ກວດສອບລາຍການຈອງ, ອະນຸມັດການຊຳລະ ແລະ ກວດສອບ check-in.',
      items: [
        ModuleItem(
          title: 'ຈອງເດີ່ນ',
          subtitle: 'ສ້າງການຈອງໜ້າຮ້ານ',
          icon: Icons.add_circle_outline,
          page: 'create_booking',
        ),
        ModuleItem(
          title: 'ຈັດການການຈອງ',
          subtitle: 'ກວດສອບລາຍການຈອງທັງໝົດ',
          icon: Icons.event_note,
          page: 'bookings',
        ),
        ModuleItem(
          title: 'ອະນຸມັດການຊຳລະ',
          subtitle: 'ກວດສະລິບ ແລະ ສະຖານະການຈ່າຍ',
          icon: Icons.verified,
          page: 'payment_approval',
        ),
        ModuleItem(
          title: 'Check-in',
          subtitle: 'ກວດສອບການເຂົ້າໃຊ້ສະໜາມ',
          icon: Icons.login,
          page: 'bookings',
        ),
        ModuleItem(
          title: 'ຍົກເລີກການຈອງ',
          subtitle: 'ກວດສອບຄຳຂໍຍົກເລີກການຈອງ',
          icon: Icons.cancel_schedule_send,
          page: 'bookings',
        ),
      ],
    );
  }

  Widget posMenuPage() {
    return modulePage(
      title: 'POS',
      subtitle: 'ຂາຍສິນຄ້າ ແລະ ຕິດຕາມປະຫວັດການຂາຍ',
      icon: Icons.point_of_sale,
      introTitle: 'ໜ້າຂາຍສິນຄ້າ',
      introDescription:
          'ໃຊ້ສຳລັບຂາຍສິນຄ້າ, ອອກບິນ ແລະ ກວດສອບປະຫວັດການຂາຍ. Stock ຈະຖືກຫຼຸດອັດຕະໂນມັດ.',
      items: [
        ModuleItem(
          title: 'ຂາຍສິນຄ້າ',
          subtitle: 'ໜ້າຂາຍສິນຄ້າ POS',
          icon: Icons.point_of_sale,
          page: 'sell_products',
        ),
        ModuleItem(
          title: 'ປະຫວັດການຂາຍ',
          subtitle: 'ກວດສອບການຂາຍທີ່ຜ່ານມາ',
          icon: Icons.history,
          page: 'sales_history',
        ),
      ],
    );
  }

  Widget reportsMenuPage() {
    if (!isOwner) return noPermissionPage();

    return modulePage(
      title: 'ລາຍງານ',
      subtitle: 'ສະຫຼຸບຂໍ້ມູນ ແລະ ລາຍຮັບຂອງລະບົບ',
      icon: Icons.bar_chart,
      introTitle: 'ໜ້າລາຍງານ',
      introDescription:
          'ໃຊ້ສຳລັບເບິ່ງລາຍງານການຈອງ, ການຂາຍ, ລາຍຮັບ ແລະ ຂໍ້ມູນລູກຄ້າ.',
      items: [
        ModuleItem(
          title: 'ລາຍງານລວມ',
          subtitle: 'ພາບລວມຂອງລາຍງານລະບົບ',
          icon: Icons.analytics,
          page: 'reports',
        ),
        ModuleItem(
          title: 'ລາຍງານການຈອງ',
          subtitle: 'ຂໍ້ມູນການຈອງ ແລະ check-in',
          icon: Icons.event_note,
          page: 'reports',
        ),
        ModuleItem(
          title: 'ລາຍງານການຂາຍ',
          subtitle: 'ຂໍ້ມູນການຂາຍສິນຄ້າ',
          icon: Icons.receipt_long,
          page: 'reports',
        ),
        ModuleItem(
          title: 'ລາຍງານລາຍຮັບ',
          subtitle: 'ສະຫຼຸບລາຍຮັບຈາກການຈອງ ແລະ POS',
          icon: Icons.payments,
          page: 'reports',
        ),
      ],
    );
  }

  Widget comingSoonPage(String title) {
    return pageWrapper(
      child: Center(
        child: Container(
          width: 560,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: softCard,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.orange.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.orange.shade50,
                child: Icon(
                  Icons.construction,
                  color: Colors.orange.shade700,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'ໜ້ານີ້ຈະຖືກພັດທະນາໃນຂັ້ນຕອນຕໍ່ໄປ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget noPermissionPage() {
    return pageWrapper(
      child: Center(
        child: Container(
          width: 560,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: softCard,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.red.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.red.shade50,
                child: Icon(
                  Icons.lock,
                  color: Colors.red.shade700,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'ບໍ່ມີສິດເຂົ້າໃຊ້',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'ໜ້ານີ້ໃຊ້ໄດ້ສະເພາະ Owner/Admin ເທົ່ານັ້ນ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget currentPage() {
    if (!isOwner) {
      if (selectedPage == 'manage' ||
          selectedPage == 'reports_menu' ||
          selectedPage == 'fields' ||
          selectedPage == 'customers' ||
          selectedPage == 'products' ||
          selectedPage == 'reports' ||
          selectedPage == 'employees') {
        return noPermissionPage();
      }
    }

    switch (selectedPage) {
      case 'dashboard':
        return dashboardPage();

      case 'manage':
        return manageMenuPage();

      case 'booking_menu':
        return bookingMenuPage();

      case 'pos_menu':
        return posMenuPage();

      case 'reports_menu':
        return reportsMenuPage();

      case 'fields':
        return FieldsPage(token: widget.token);

      case 'customers':
        return CustomersPage(token: widget.token);

      case 'products':
        return ProductsPage(token: widget.token);

      case 'bookings':
        return BookingsPage(token: widget.token);

      case 'create_booking':
        return CreateBookingPage(token: widget.token);

      case 'payment_approval':
        return PaymentApprovalPage(token: widget.token);

      case 'sell_products':
        return SellProductsPage(token: widget.token);

      case 'sales_history':
        return SalesHistoryPage(token: widget.token);

      case 'reports':
        return ReportsPage(token: widget.token);

      case 'employees':
        return comingSoonPage('ຈັດການພະນັກງານ');

      default:
        return dashboardPage();
    }
  }

  Widget sidebar() {
    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    primaryGreen,
                    darkGreen,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.sports_soccer,
                    color: Colors.white,
                    size: 34,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ST Football\nAdmin',
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.2,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  sidebarItem(
                    title: 'ໜ້າຫຼັກ',
                    icon: Icons.dashboard,
                    page: 'dashboard',
                  ),
                  if (isOwner)
                    sidebarItem(
                      title: 'ຈັດການ',
                      icon: Icons.folder_copy,
                      page: 'manage',
                      activePages: const [
                        'employees',
                        'customers',
                        'fields',
                        'products',
                      ],
                    ),
                  sidebarItem(
                    title: 'ການຈອງ',
                    icon: Icons.calendar_month,
                    page: 'booking_menu',
                    activePages: const [
                      'create_booking',
                      'bookings',
                      'payment_approval',
                    ],
                  ),
                  sidebarItem(
                    title: 'POS',
                    icon: Icons.point_of_sale,
                    page: 'pos_menu',
                    activePages: const [
                      'sell_products',
                      'sales_history',
                    ],
                  ),
                  if (isOwner)
                    sidebarItem(
                      title: 'ລາຍງານ',
                      icon: Icons.bar_chart,
                      page: 'reports_menu',
                      activePages: const [
                        'reports',
                      ],
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                'ອອກຈາກລະບົບ',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      body: Row(
        children: [
          sidebar(),
          Expanded(
            child: currentPage(),
          ),
        ],
      ),
    );
  }
}

class ModuleItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String page;

  ModuleItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.page,
  });
}

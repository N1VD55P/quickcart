import 'package:flutter/material.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/products_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/users_tab.dart';
import 'tabs/inventory_tab.dart';
import 'tabs/reviews_tab.dart';
import 'tabs/coupons_tab.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    DashboardTab(),
    ProductsTab(),
    OrdersTab(),
    UsersTab(),
    InventoryTab(),
    ReviewsTab(),
    CouponsTab(),
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.inventory_2_outlined),
      activeIcon: Icon(Icons.inventory_2),
      label: 'Products',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long_outlined),
      activeIcon: Icon(Icons.receipt_long),
      label: 'Orders',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.people_outline),
      activeIcon: Icon(Icons.people),
      label: 'Users',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.warehouse_outlined),
      activeIcon: Icon(Icons.warehouse),
      label: 'Inventory',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.star_outline),
      activeIcon: Icon(Icons.star),
      label: 'Reviews',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.discount_outlined),
      activeIcon: Icon(Icons.discount),
      label: 'Coupons',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_navItems[_currentIndex].label!),
          backgroundColor: const Color.fromARGB(221, 104, 103, 103),
          foregroundColor: Colors.white,
          actions: [
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Exit admin panel?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Exit',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout, color: Colors.white, size: 18),
              label: const Text('Exit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: IndexedStack(index: _currentIndex, children: _tabs),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color.fromARGB(221, 72, 72, 72),
          unselectedItemColor: Colors.grey,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: _navItems,
        ),
      ),
    );
  }
}
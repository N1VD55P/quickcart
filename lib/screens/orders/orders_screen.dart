import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/order.dart';
import 'order_detail_screen.dart';
import '../shop/home_screen.dart';

class OrdersScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const OrdersScreen({super.key, this.onBack});

  String get _userEmail =>
      Hive.box('settings').get('currentUser', defaultValue: '');

  List<Order> _getUserOrders() {
    return Hive.box<Order>(
        'orders',
      ).values.where((o) => o.userEmail == _userEmail).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  Color _statusColor(String status, Color primaryBlue, Color greyText) {
    switch (status) {
      case 'Delivered':
        return Colors.green;
      case 'Shipped':
        return primaryBlue;
      case 'Packed':
        return Colors.orange;
      default:
        return greyText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final primaryBlue = Theme.of(context).colorScheme.primary;
    final darkText = Theme.of(context).colorScheme.onSurface;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      }
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(38),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'My Orders',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<Order>('orders').listenable(),
                builder: (context, box, _) {
                  final orders = _getUserOrders();
                  if (orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 72,
                            color: greyText.withAlpha(100),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No orders yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: darkText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your placed orders will appear here',
                            style: TextStyle(fontSize: 14, color: greyText),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(context, orders[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    final primaryBlue = Theme.of(context).colorScheme.primary;
    final darkText = Theme.of(context).colorScheme.onSurface;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);
    final cardWhite = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceGreen = isDark
        ? const Color(0xFF66BB6A)
        : const Color(0xFF2E7D32);
    final statusColor = _statusColor(order.status, primaryBlue, greyText);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              '${order.dateTime.day} ${_monthName(order.dateTime.month)} ${order.dateTime.year}',
              style: TextStyle(fontSize: 13, color: greyText),
            ),
            const SizedBox(height: 8),

            Text(
              '${order.items.length} item${order.items.length > 1 ? 's' : ''}  •  ${order.items.map((i) => i.name).take(2).join(', ')}${order.items.length > 2 ? '...' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: greyText),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${order.total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: priceGreen,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: greyText,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

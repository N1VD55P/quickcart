import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../../models/user.dart';
import '../../../models/order.dart';
import '../../../models/review.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  Future<Map<String, int>> _fetchProductStats() async {
    final snap = await FirebaseFirestore.instance.collection('products').get();
    int total = snap.docs.length;
    int lowStock = snap.docs.where((d) {
      final stock = (d.data()['stock'] as num).toInt();
      return stock > 0 && stock <= 5;
    }).length;
    int outOfStock = snap.docs.where((d) {
      return (d.data()['stock'] as num).toInt() == 0;
    }).length;
    return {'total': total, 'lowStock': lowStock, 'outOfStock': outOfStock};
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Order>('orders').listenable(),
      builder: (context, Box<Order> orderBox, _) {
        final userBox = Hive.box<User>('users');
        final reviewBox = Hive.box<Review>('reviews');

        final allOrders = orderBox.values.toList();
        final totalRevenue = allOrders.fold<double>(
          0,
          (sum, o) => sum + o.total,
        );
        final todayOrders = allOrders.where((o) {
          final now = DateTime.now();
          return o.dateTime.year == now.year &&
              o.dateTime.month == now.month &&
              o.dateTime.day == now.day;
        }).length;

        final placedCount = allOrders.where((o) => o.status == 'Placed').length;
        final shippedCount = allOrders
            .where((o) => o.status == 'Shipped')
            .length;
        final deliveredCount = allOrders
            .where((o) => o.status == 'Delivered')
            .length;
        final cancelledCount = allOrders
            .where((o) => o.status == 'Cancelled')
            .length;

        final avgRating = reviewBox.values.isEmpty
            ? 0.0
            : reviewBox.values.map((r) => r.rating).reduce((a, b) => a + b) /
                  reviewBox.values.length;

        return FutureBuilder<Map<String, int>>(
          future: _fetchProductStats(),
          builder: (context, snapshot) {
            final productTotal = snapshot.data?['total'] ?? 0;
            final lowStock = snapshot.data?['lowStock'] ?? 0;
            final outOfStock = snapshot.data?['outOfStock'] ?? 0;
            final productLoading =
                snapshot.connectionState == ConnectionState.waiting;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _SectionHeader('Overview'),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _StatCard(
                      label: 'Total Users',
                      value: '${userBox.length}',
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                    _StatCard(
                      label: 'Total Products',
                      value: productLoading ? '…' : '$productTotal',
                      icon: Icons.inventory_2,
                      color: Colors.purple,
                    ),
                    _StatCard(
                      label: 'Total Orders',
                      value: '${allOrders.length}',
                      icon: Icons.receipt_long,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      label: 'Total Revenue',
                      value: '₹${totalRevenue.toStringAsFixed(0)}',
                      icon: Icons.currency_rupee,
                      color: Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Today ─────────────────────────────────────────
                const _SectionHeader('Today'),
                const SizedBox(height: 8),
                _InfoRow('Orders today', '$todayOrders'),
                _InfoRow('Total reviews', '${reviewBox.length}'),
                _InfoRow(
                  'Avg rating',
                  avgRating > 0 ? avgRating.toStringAsFixed(1) : 'N/A',
                ),

                const SizedBox(height: 20),

                // ── Order status breakdown ─────────────────────────
                const _SectionHeader('Order Status Breakdown'),
                const SizedBox(height: 8),
                _InfoRow('Placed', '$placedCount', valueColor: Colors.blue),
                _InfoRow('Shipped', '$shippedCount', valueColor: Colors.orange),
                _InfoRow(
                  'Delivered',
                  '$deliveredCount',
                  valueColor: Colors.green,
                ),
                _InfoRow(
                  'Cancelled',
                  '$cancelledCount',
                  valueColor: Colors.red,
                ),

                const SizedBox(height: 20),

                // ── Inventory alerts ───────────────────────────────
                const _SectionHeader('Inventory Alerts'),
                const SizedBox(height: 8),
                _InfoRow(
                  'Low stock (≤5)',
                  productLoading ? '…' : '$lowStock',
                  valueColor: lowStock > 0 ? Colors.orange : Colors.green,
                ),
                _InfoRow(
                  'Out of stock',
                  productLoading ? '…' : '$outOfStock',
                  valueColor: outOfStock > 0 ? Colors.red : Colors.green,
                ),

                const SizedBox(height: 20),

                // ── Top spending users ─────────────────────────────
                const _SectionHeader('Top 5 Users by Spend'),
                const SizedBox(height: 8),
                _buildTopUsers(orderBox, userBox),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTopUsers(Box<Order> orderBox, Box<User> userBox) {
    final spendMap = <String, double>{};
    for (final order in orderBox.values) {
      spendMap[order.userEmail] =
          (spendMap[order.userEmail] ?? 0) + order.total;
    }

    final sorted = spendMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();

    if (top5.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No orders yet', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: top5.map((entry) {
        final user = userBox.values
            .where((u) => u.email == entry.key)
            .firstOrNull;
        return _InfoRow(
          user?.name ?? entry.key,
          '₹${entry.value.toStringAsFixed(0)}',
          valueColor: Colors.green,
        );
      }).toList(),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color.fromARGB(255, 245, 244, 244),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

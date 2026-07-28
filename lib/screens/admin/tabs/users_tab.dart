import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/user.dart';
import '../../../models/order.dart';
import '../../../models/address.dart';
import '../../../models/review.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<User> _filtered(List<User> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all.where((u) {
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();
  }

  List<Order> _userOrders(String email) {
    final orderBox = Hive.box<Order>('orders');
    return orderBox.values.where((o) => o.userEmail == email).toList();
  }

  double _totalSpent(String email) {
    return _userOrders(email).fold(0.0, (sum, o) => sum + o.total);
  }

  Future<void> _deleteUser(BuildContext context, User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Delete ${user.name}? This will also remove all their orders, addresses, and reviews.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Delete orders
    final orderBox = Hive.box<Order>('orders');
    final userOrders =
        orderBox.values.where((o) => o.userEmail == user.email).toList();
    for (final o in userOrders) await o.delete();

    // Delete addresses
    final addressBox = Hive.box<Address>('addresses');
    final userAddresses = addressBox.values
        .where((a) => a.userEmail == user.email)
        .toList();
    for (final a in userAddresses) await a.delete();

    // Delete reviews
    final reviewBox = Hive.box<Review>('reviews');
    final userReviews =
        reviewBox.values.where((r) => r.userEmail == user.email).toList();
    for (final r in userReviews) await r.delete();

    // Delete user last
    await user.delete();

    if (context.mounted) Navigator.pop(context); // close bottom sheet
  }

  void _showUserDetails(BuildContext context, User user) {
    final orders = _userOrders(user.email);
    final spent = _totalSpent(user.email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Avatar + name
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(user.email,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Details
              _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: user.phone.isNotEmpty ? user.phone : '—'),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.shopping_bag_outlined,
                label: 'Total Orders',
                value: '${orders.length}',
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.currency_rupee_rounded,
                label: 'Total Spent',
                value: '₹${spent.toStringAsFixed(0)}',
              ),

              if (orders.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Recent Orders',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54)),
                const SizedBox(height: 8),
                ...orders
                    .take(3)
                    .map((o) => _MiniOrderRow(order: o)),
              ],

              const SizedBox(height: 24),

              // Delete button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => _deleteUser(context, user),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete User',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search bar ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or email…',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
          ),
        ),

        // ── User list ─────────────────────────────────────────────
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: Hive.box<User>('users').listenable(),
            builder: (context, Box<User> box, _) {
              final users = _filtered(box.values.toList());

              if (users.isEmpty) {
                return const Center(
                  child: Text('No users found',
                      style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final user = users[i];
                  final orders = _userOrders(user.email);
                  final spent = _totalSpent(user.email);

                  return GestureDetector(
                    onTap: () => _showUserDetails(context, user),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.blue.shade50,
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87)),
                                const SizedBox(height: 2),
                                Text(user.email,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black45),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                if (user.phone.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(user.phone,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black45)),
                                ],
                              ],
                            ),
                          ),

                          // Stats
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${orders.length} orders',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${spent.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green),
                              ),
                            ],
                          ),

                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right_rounded,
                              size: 18, color: Colors.black26),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black38),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.black54)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }
}

class _MiniOrderRow extends StatelessWidget {
  final Order order;
  const _MiniOrderRow({required this.order});

  Color _statusColor(String s) {
    switch (s) {
      case 'Placed': return Colors.blue;
      case 'Packed': return Colors.purple;
      case 'Shipped': return Colors.orange;
      case 'Delivered': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '#${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor(order.status).withAlpha(25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _statusColor(order.status).withAlpha(80)),
            ),
            child: Text(order.status,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(order.status))),
          ),
          const SizedBox(width: 8),
          Text('₹${order.total.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
        ],
      ),
    );
  }
}
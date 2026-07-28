import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/order.dart';
import '../../../models/address.dart';
import '../../../models/cart_item.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All';

  static const List<String> _statuses = [
    'All',
    'Placed',
    'Packed',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Order> _filtered(List<Order> all) {
    var list = all;

    if (_statusFilter != 'All') {
      list = list.where((o) => o.status == _statusFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((o) =>
              o.id.toLowerCase().contains(q) ||
              o.userEmail.toLowerCase().contains(q))
          .toList();
    }

    // Newest first
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  Future<void> _updateStatus(Order order, String newStatus) async {
    order.status = newStatus;
    await order.save();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        _buildStatusFilter(),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: Hive.box<Order>('orders').listenable(),
            builder: (context, Box<Order> box, _) {
              final filtered = _filtered(box.values.toList());

              if (filtered.isEmpty) {
                return const Center(
                  child: Text('No orders found',
                      style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _OrderTile(
                  order: filtered[i],
                  onStatusChange: (newStatus) =>
                      _updateStatus(filtered[i], newStatus),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by order ID or email…',
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
    );
  }

  Widget _buildStatusFilter() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _statuses.length,
        itemBuilder: (_, i) {
          final s = _statuses[i];
          final selected = s == _statusFilter;
          return GestureDetector(
            onTap: () => setState(() => _statusFilter = s),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? Colors.black87 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      selected ? Colors.black87 : Colors.grey.shade300,
                ),
              ),
              child: Text(
                s,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.black54,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Order tile ────────────────────────────────────────────────────────────────

class _OrderTile extends StatelessWidget {
  final Order order;
  final void Function(String newStatus) onStatusChange;

  const _OrderTile({
    required this.order,
    required this.onStatusChange,
  });

  static const List<String> _statuses = [
    'Placed',
    'Packed',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  Color _statusColor(String status) {
    switch (status) {
      case 'Placed': return Colors.blue;
      case 'Packed': return Colors.purple;
      case 'Shipped': return Colors.orange;
      case 'Delivered': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Address? _getAddress() {
    final box = Hive.box<Address>('addresses');
    return box.values
        .where((a) => a.id == order.addressId)
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final address = _getAddress();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.userEmail,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black45),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withAlpha(80)),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // ── Items ───────────────────────────────────────────
          ...order.items.map((item) => _ItemRow(item: item)),

          const SizedBox(height: 8),

          // ── Address ─────────────────────────────────────────
          if (address != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${address.fullName}, ${address.line1}, ${address.city} - ${address.pincode}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

          // ── Footer: date + total ─────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(order.dateTime),
                style: const TextStyle(
                    fontSize: 12, color: Colors.black45),
              ),
              Text(
                '₹${order.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Status updater ───────────────────────────────────
          Row(
            children: [
              const Text('Update:',
                  style: TextStyle(fontSize: 12, color: Colors.black45)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: order.status,
                  isDense: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black87),
                  items: _statuses
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null && v != order.status) {
                      onStatusChange(v);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Item row inside order tile ────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final CartItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 5, color: Colors.black38),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                  fontSize: 12, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'x${item.quantity}  ₹${(item.price * item.quantity).toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
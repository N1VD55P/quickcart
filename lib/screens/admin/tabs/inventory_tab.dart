import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryTab extends StatefulWidget {
  const InventoryTab({super.key});

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> {
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Electronics',
    'Fashion',
    'Home & Kitchen',
    'Sports',
    'Books',
    'Beauty',
  ];

  Query<Map<String, dynamic>> get _query {
    final col = FirebaseFirestore.instance.collection('products');
    if (_selectedCategory == 'All') return col;
    return col.where('category', isEqualTo: _selectedCategory);
  }

  Color _stockColor(int stock) {
    if (stock == 0) return Colors.red;
    if (stock <= 5) return Colors.orange;
    return Colors.green;
  }

  String _stockLabel(int stock) {
    if (stock == 0) return 'Out of stock';
    if (stock <= 5) return 'Low stock';
    return 'In stock';
  }

  // Sort: out of stock first, then low stock, then in stock
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sorted(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return [...docs]..sort((a, b) {
        final sa = (a.data()['stock'] as num).toInt();
        final sb = (b.data()['stock'] as num).toInt();
        int priority(int s) => s == 0 ? 0 : s <= 5 ? 1 : 2;
        return priority(sa).compareTo(priority(sb));
      });
  }

  Future<void> _showStockDialog(
      BuildContext context,
      String docId,
      String productName,
      int currentStock) async {
    final controller =
        TextEditingController(text: currentStock.toString());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Update Stock', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(productName,
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'New stock quantity',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final newStock = int.tryParse(controller.text.trim());
    if (newStock == null || newStock < 0) return;

    await FirebaseFirestore.instance
        .collection('products')
        .doc(docId)
        .update({'stock': newStock});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .snapshots(),
      builder: (context, allSnapshot) {
        // Compute summary from all products regardless of category filter
        int totalProducts = 0;
        int lowStock = 0;
        int outOfStock = 0;

        if (allSnapshot.hasData) {
          final allDocs = allSnapshot.data!.docs;
          totalProducts = allDocs.length;
          for (final doc in allDocs) {
            final stock = (doc.data()['stock'] as num).toInt();
            if (stock == 0) outOfStock++;
            else if (stock <= 5) lowStock++;
          }
        }

        return Column(
          children: [
            // ── Summary row ───────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  _SummaryCell(
                    label: 'Total',
                    value: '$totalProducts',
                    color: Colors.black87,
                  ),
                  _Divider(),
                  _SummaryCell(
                    label: 'Low Stock',
                    value: '$lowStock',
                    color: Colors.orange,
                  ),
                  _Divider(),
                  _SummaryCell(
                    label: 'Out of Stock',
                    value: '$outOfStock',
                    color: Colors.red,
                  ),
                ],
              ),
            ),

            // ── Category filter ───────────────────────────────────
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final selected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.black87
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? Colors.black87
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : Colors.black54,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // ── Product list ──────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _query.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Failed to load products'));
                  }

                  final docs = _sorted(snapshot.data?.docs ?? []);

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No products found',
                          style: TextStyle(color: Colors.grey)),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final doc = docs[i];
                      final data = doc.data();
                      final stock =
                          (data['stock'] as num).toInt();
                      final name =
                          data['name'] as String? ?? '—';
                      final category =
                          data['category'] as String? ?? '—';
                      final imageUrl =
                          data['imageUrl'] as String? ?? '';
                      final stockColor = _stockColor(stock);
                      final stockLabel = _stockLabel(stock);

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: stock == 0
                                ? Colors.red.shade100
                                : stock <= 5
                                    ? Colors.orange.shade100
                                    : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Product image or icon
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                                Icons
                                                    .shopping_bag_outlined,
                                                color: Colors.black26,
                                                size: 24),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: Colors.black26,
                                      size: 24),
                            ),

                            const SizedBox(width: 12),

                            // Name + category
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87)),
                                  const SizedBox(height: 3),
                                  Text(category,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black45)),
                                  const SizedBox(height: 6),
                                  // Stock badge
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          stockColor.withAlpha(25),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      border: Border.all(
                                          color: stockColor
                                              .withAlpha(80)),
                                    ),
                                    child: Text(
                                      '$stock units · $stockLabel',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: stockColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Edit stock button
                            GestureDetector(
                              onTap: () => _showStockDialog(
                                  context, doc.id, name, stock),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                    Icons.edit_rounded,
                                    size: 16,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Colors.black45)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.grey.shade200,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/coupon.dart';

class CouponsTab extends StatefulWidget {
  const CouponsTab({super.key});

  @override
  State<CouponsTab> createState() => _CouponsTabState();
}

class _CouponsTabState extends State<CouponsTab> {
  @override
  void initState() {
    super.initState();
    _seedIfEmpty();
  }

  void _seedIfEmpty() {
    final box = Hive.box<Coupon>('coupons');
    if (box.isNotEmpty) return;
    box.add(Coupon(code: 'SAVE10', type: 'percent', value: 10));
    box.add(Coupon(code: 'FLAT50', type: 'flat', value: 50));
    box.add(Coupon(code: 'SAVE20', type: 'percent', value: 20));
  }

  String _displayValue(Coupon c) {
    return c.type == 'percent'
        ? '${c.value.toStringAsFixed(0)}% off'
        : '₹${c.value.toStringAsFixed(0)} flat off';
  }

  Future<void> _deleteCoupon(Coupon coupon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Coupon',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Delete coupon "${coupon.code}"?'),
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
    if (confirmed == true) await coupon.delete();
  }

  void _showAddSheet() {
    _showCouponSheet(context);
  }

  void _showEditSheet(Coupon coupon) {
    _showCouponSheet(context, existing: coupon);
  }

  void _showCouponSheet(BuildContext context, {Coupon? existing}) {
    final codeController =
        TextEditingController(text: existing?.code ?? '');
    final valueController = TextEditingController(
        text: existing != null
            ? existing.value.toStringAsFixed(0)
            : '');
    String selectedType = existing?.type ?? 'percent';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 16),

              Text(
                existing == null ? 'Add Coupon' : 'Edit Coupon',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),

              // Code field
              TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Coupon Code',
                  hintText: 'e.g. SAVE10',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
                onChanged: (v) {
                  codeController.value = codeController.value.copyWith(
                    text: v.toUpperCase(),
                    selection: TextSelection.collapsed(
                        offset: v.length),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Type toggle
              Row(
                children: [
                  const Text('Type:',
                      style: TextStyle(
                          fontSize: 13, color: Colors.black54)),
                  const SizedBox(width: 12),
                  _TypeChip(
                    label: 'Percentage',
                    selected: selectedType == 'percent',
                    onTap: () =>
                        setSheetState(() => selectedType = 'percent'),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: 'Flat ₹',
                    selected: selectedType == 'flat',
                    onTap: () =>
                        setSheetState(() => selectedType = 'flat'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Value field
              TextField(
                controller: valueController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: selectedType == 'percent'
                      ? 'Discount %'
                      : 'Discount Amount (₹)',
                  hintText:
                      selectedType == 'percent' ? 'e.g. 10' : 'e.g. 50',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final code = codeController.text.trim().toUpperCase();
                    final value =
                        double.tryParse(valueController.text.trim());

                    if (code.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Enter a coupon code')),
                      );
                      return;
                    }
                    if (value == null || value <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Enter a valid discount value')),
                      );
                      return;
                    }
                    if (selectedType == 'percent' && value > 100) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Percentage cannot exceed 100')),
                      );
                      return;
                    }

                    final box = Hive.box<Coupon>('coupons');

                    if (existing == null) {
                      // Check duplicate code
                      final duplicate = box.values
                          .any((c) => c.code == code);
                      if (duplicate) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Coupon "$code" already exists')),
                        );
                        return;
                      }
                      await box.add(Coupon(
                        code: code,
                        type: selectedType,
                        value: value,
                      ));
                    } else {
                      existing.code = code;
                      existing.type = selectedType;
                      existing.value = value;
                      await existing.save();
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    existing == null ? 'Add Coupon' : 'Save Changes',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Coupon',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Coupon>('coupons').listenable(),
        builder: (context, Box<Coupon> box, _) {
          final coupons = box.values.toList();

          if (coupons.isEmpty) {
            return const Center(
              child: Text('No coupons yet',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            itemCount: coupons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final coupon = coupons[i];
              final isPercent = coupon.type == 'percent';

              return Dismissible(
                key: ValueKey(coupon.key),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_rounded,
                      color: Colors.white, size: 24),
                ),
                confirmDismiss: (_) async {
                  await _deleteCoupon(coupon);
                  return false;
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      // Coupon icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isPercent
                              ? Colors.purple.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isPercent
                              ? Icons.percent_rounded
                              : Icons.currency_rupee_rounded,
                          size: 22,
                          color: isPercent
                              ? Colors.purple
                              : Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Code + value
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(coupon.code,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 3),
                            Text(_displayValue(coupon),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black45)),
                          ],
                        ),
                      ),

                      // Edit button
                      GestureDetector(
                        onTap: () => _showEditSheet(coupon),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.edit_rounded,
                              size: 16, color: Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Delete button
                      GestureDetector(
                        onTap: () => _deleteCoupon(coupon),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              size: 16, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Type chip ─────────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.black87 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                selected ? Colors.black87 : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }
}
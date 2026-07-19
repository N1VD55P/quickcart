import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../models/address.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../shop/cart_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  static const List<String> _statusSteps = ['Placed', 'Packed', 'Shipped', 'Delivered'];

  int get _currentStatusIndex => _statusSteps.indexOf(order.status);

  Address? get _address {
    final box = Hive.box<Address>('addresses');
    return box.values.cast<Address?>().firstWhere(
      (a) => a?.id == order.addressId,
      orElse: () => null,
    );
  }

  String _monthName(int month) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[month - 1];
  }

  Future<void> _reorder(BuildContext context) async {
    final primaryBlue = Theme.of(context).colorScheme.primary;
    final cart = context.read<CartProvider>();
    final productsBox = Hive.box<Product>('products');

    for (final item in order.items) {
      final matches = productsBox.values.where((p) => p.id == item.productId);
      if (matches.isNotEmpty) {
        await cart.addToCart(matches.first);
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Items added to cart'),
          backgroundColor: primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final primaryBlue = Theme.of(context).colorScheme.primary;
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
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(38),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Order #${order.id}',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Placed on ${order.dateTime.day} ${_monthName(order.dateTime.month)} ${order.dateTime.year}',
                      style: TextStyle(fontSize: 13, color: greyText),
                    ),
                    const SizedBox(height: 20),

                    _sectionTitle(context, 'Order Status'),
                    const SizedBox(height: 14),
                    _buildStatusTimeline(context),
                    const SizedBox(height: 20),

                    _sectionTitle(context, 'Items Ordered'),
                    const SizedBox(height: 10),
                    _buildItemsList(context),
                    const SizedBox(height: 20),

                    _sectionTitle(context, 'Delivery Address'),
                    const SizedBox(height: 10),
                    _buildAddressCard(context),
                    const SizedBox(height: 20),

                    _sectionTitle(context, 'Price Summary'),
                    const SizedBox(height: 10),
                    _buildPriceSummary(context),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () => _reorder(context),
                        icon: const Icon(Icons.replay_rounded, size: 20),
                        label: const Text('Reorder',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(BuildContext context) {
    final primaryBlue = Theme.of(context).colorScheme.primary;
    final darkText = Theme.of(context).colorScheme.onSurface;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);
    final cardWhite = Theme.of(context).cardColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: List.generate(_statusSteps.length, (index) {
          final isDone = index <= _currentStatusIndex;
          final isCurrent = index == _currentStatusIndex;
          final isLast = index == _statusSteps.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: isDone ? primaryBlue : greyText.withAlpha(60),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDone ? Icons.check_rounded : Icons.circle,
                      color: Colors.white,
                      size: isDone ? 14 : 8,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2, height: 36,
                      color: index < _currentStatusIndex
                          ? primaryBlue
                          : greyText.withAlpha(60),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _statusSteps[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isDone ? darkText : greyText,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildItemsList(BuildContext context) {
    final darkText = Theme.of(context).colorScheme.onSurface;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);
    final cardWhite = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceGreen = isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32);

    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: order.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == order.items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkText)),
                    ),
                    const SizedBox(width: 8),
                    Text('x${item.quantity}', style: TextStyle(fontSize: 13, color: greyText)),
                    const SizedBox(width: 12),
                    Text('₹${(item.price * item.quantity).toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: priceGreen)),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 14, endIndent: 14),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context) {
    final primaryBlue = Theme.of(context).colorScheme.primary;
    final darkText = Theme.of(context).colorScheme.onSurface;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);
    final cardWhite = Theme.of(context).cardColor;
    final address = _address;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: address == null
          ? Text('Address not found', style: TextStyle(color: greyText))
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_rounded, color: primaryBlue, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(address.fullName,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: darkText)),
                      const SizedBox(height: 2),
                      Text('${address.line1}, ${address.city} - ${address.pincode}',
                          style: TextStyle(fontSize: 13, color: greyText, height: 1.4)),
                      Text(address.phone, style: TextStyle(fontSize: 13, color: greyText)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPriceSummary(BuildContext context) {
    final cardWhite = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceGreen = isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _priceRow(context, 'Items (${order.items.length})',
              '₹${order.items.fold(0.0, (s, i) => s + i.price * i.quantity).toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _priceRow(context, 'Delivery', 'FREE', valueColor: Colors.green),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
          _priceRow(context, 'Total', '₹${order.total.toStringAsFixed(0)}',
              isBold: true, valueColor: priceGreen),
        ],
      ),
    );
  }

  Widget _priceRow(BuildContext context, String label, String value,
      {bool isBold = false, Color? valueColor}) {
    final darkText = Theme.of(context).colorScheme.onSurface;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
            fontSize: 14,
            color: isBold ? darkText : greyText,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400)),
        Text(value, style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? darkText)),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final darkText = Theme.of(context).colorScheme.onSurface;
    return Text(title,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: darkText));
  }
}
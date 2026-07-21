import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/address.dart';
import '../../models/order.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import 'order_success_screen.dart';
import '../profile/address_book_screen.dart';

const _discountRed = Color(0xFFD32F2F); 

const Map<String, dynamic> _coupons = {
  'SAVE10': {'type': 'percent', 'value': 10},
  'FLAT50': {'type': 'flat', 'value': 50},
  'SAVE20': {'type': 'percent', 'value': 20},
};

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _couponController = TextEditingController();
  String? _appliedCoupon;
  double _discount = 0;
  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  String get _userEmail =>
      Hive.box('settings').get('currentUser', defaultValue: '');

  Address? get _defaultAddress {
    final box = Hive.box<Address>('addresses');
    final userAddresses =
        box.values.where((a) => a.userEmail == _userEmail).toList();
    if (userAddresses.isEmpty) return null;
    final defaults = userAddresses.where((a) => a.isDefault).toList();
    return defaults.isNotEmpty ? defaults.first : userAddresses.first;
  }

  double _finalTotal(double subtotal) =>
      (subtotal - _discount).clamp(0, double.infinity);

  void _applyCoupon(double subtotal) {
    final errorColor = Theme.of(context).colorScheme.error;
    final code = _couponController.text.trim().toUpperCase();
    if (!_coupons.containsKey(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid or expired coupon code'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final coupon = _coupons[code]!;
    double discount = 0;
    if (coupon['type'] == 'percent') {
      discount = subtotal * (coupon['value'] / 100);
    } else {
      discount = coupon['value'].toDouble();
    }
    setState(() {
      _appliedCoupon = code;
      _discount = discount;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coupon applied! You save ₹${discount.toStringAsFixed(0)}'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _discount = 0;
      _couponController.clear();
    });
  }

  Future<void> _placeOrder(CartProvider cart) async {
    final errorColor = Theme.of(context).colorScheme.error;
    if (_defaultAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add a delivery address first'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    final orderId = const Uuid().v4().substring(0, 8).toUpperCase();
    final order = Order(
      id: orderId,
      userEmail: _userEmail,
      items: cart.items.toList(),
      total: _finalTotal(cart.total),
      dateTime: DateTime.now(),
      status: 'Placed',
      addressId: _defaultAddress!.id,
    );

    await Hive.box<Order>('orders').add(order);
    await cart.clearCart();

    setState(() => _isPlacingOrder = false);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(orderId: orderId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final primaryBlue = Theme.of(context).colorScheme.primary;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);
    final cardWhite = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceGreen =
        isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32);

    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final subtotal = cart.total;
        final final_ = _finalTotal(subtotal);

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  color: primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
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
                        'Checkout',
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(context, 'Delivery Address'),
                        const SizedBox(height: 10),
                        _buildAddressCard(context),
                        const SizedBox(height: 20),

                        _sectionTitle(context, 'Order Items (${cart.itemCount})'),
                        const SizedBox(height: 10),
                        ...cart.items.map(
                            (item) => _buildOrderItemTile(context, item)),
                        const SizedBox(height: 20),

                        _sectionTitle(context, 'Coupon Code'),
                        const SizedBox(height: 10),
                        _buildCouponField(context, subtotal),
                        const SizedBox(height: 20),

                        _sectionTitle(context, 'Price Summary'),
                        const SizedBox(height: 10),
                        _buildPriceSummary(context, subtotal, final_),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: cardWhite,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                                fontSize: 14, color: greyText),
                          ),
                          Text(
                            '₹${final_.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: priceGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isPlacingOrder
                              ? null
                              : () => _placeOrder(cart),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isPlacingOrder
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Place Order',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressCard(BuildContext context) {
    final primaryBlue = Theme.of(context).colorScheme.primary;
    final darkText = Theme.of(context).colorScheme.onSurface;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);
    final cardWhite = Theme.of(context).cardColor;
    final address = _defaultAddress;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: address == null
          ? Row(
              children: [
                Icon(Icons.location_off_outlined, color: greyText),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No address added yet',
                    style: TextStyle(color: greyText),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddressBookScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Add',
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_rounded, color: primaryBlue, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address.fullName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${address.line1}, ${address.city} - ${address.pincode}',
                        style: TextStyle(
                          fontSize: 13,
                          color: greyText,
                          height: 1.4,
                        ),
                      ),
                      Text(
                        address.phone,
                        style: TextStyle(fontSize: 13, color: greyText),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: primaryBlue.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'DEFAULT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOrderItemTile(BuildContext context, CartItem item) {
    final darkText = Theme.of(context).colorScheme.onSurface;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);
    final cardWhite = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceGreen =
        isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'x${item.quantity}',
            style: TextStyle(fontSize: 13, color: greyText),
          ),
          const SizedBox(width: 12),
          Text(
            '₹${(item.price * item.quantity).toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: priceGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponField(BuildContext context, double subtotal) {
    final primaryBlue = Theme.of(context).colorScheme.primary;
    final darkText = Theme.of(context).colorScheme.onSurface;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);
    final cardWhite = Theme.of(context).cardColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _appliedCoupon != null
          ? Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$_appliedCoupon applied — You save ₹${_discount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _removeCoupon,
                  child: Icon(Icons.close_rounded, color: greyText, size: 20),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(
                      fontSize: 14,
                      color: darkText,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      hintStyle: TextStyle(
                        color: greyText,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _applyCoupon(subtotal),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPriceSummary(
      BuildContext context, double subtotal, double final_) {
    final cardWhite = Theme.of(context).cardColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _priceRow(context, 'Subtotal', '₹${subtotal.toStringAsFixed(0)}'),
          if (_discount > 0) ...[
            const SizedBox(height: 8),
            _priceRow(
              context,
              'Discount ($_appliedCoupon)',
              '-₹${_discount.toStringAsFixed(0)}',
              valueColor: _discountRed,
            ),
          ],
          const SizedBox(height: 8),
          _priceRow(context, 'Delivery', 'FREE', valueColor: Colors.green),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          _priceRow(
            context,
            'Total',
            '₹${final_.toStringAsFixed(0)}',
            isBold: true,
            valueColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF66BB6A)
                : const Color(0xFF2E7D32),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    final darkText = Theme.of(context).colorScheme.onSurface;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isBold ? darkText : greyText,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? darkText,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final darkText = Theme.of(context).colorScheme.onSurface;
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: darkText,
      ),
    );
  }
}
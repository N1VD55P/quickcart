import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/cart_item.dart';

const _primaryBlue = Color(0xFF1565C0);
const _discountRed = Color(0xFFD32F2F);

class HomeAppBar extends StatelessWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onWishlistTap;
  final VoidCallback onCartTap;
  final bool isSearchScreen;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onBackTap;

  const HomeAppBar({
    super.key,
    required this.onSearchTap,
    required this.onWishlistTap,
    required this.onCartTap,
    this.isSearchScreen = false,
    this.controller,
    this.onChanged,
    this.onBackTap,
  });

  Widget _appBarIcon(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(38),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _primaryBlue,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (isSearchScreen)
            GestureDetector(
              onTap: onBackTap,
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

          if (isSearchScreen) const SizedBox(width: 10),

          Expanded(
            child: Container(
              height: 42,
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(47),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withAlpha(70)),
              ),
              child: isSearchScreen
                  ? TextField(
                      controller: controller,
                      autofocus: true,
                      onChanged: onChanged,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Search products...",
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white70,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () {
                            controller?.clear();
                            onChanged?.call("");
                          },
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: onSearchTap,
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.white70),
                          SizedBox(width: 10),
                          Text(
                            "Search products...",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 12),
          if (!isSearchScreen) ...[
            _appBarIcon(Icons.favorite_border_rounded, onTap: onWishlistTap),
            const SizedBox(width: 8),
            Stack(
              children: [
                _appBarIcon(Icons.shopping_cart_outlined, onTap: onCartTap),
                Positioned(
                  right: 0,
                  top: 0,
                  child: ValueListenableBuilder(
                    valueListenable: Hive.box<CartItem>('cart').listenable(),
                    builder: (context, box, _) {
                      final count = box.length;
                      if (count == 0) return const SizedBox.shrink();
                      return Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: _discountRed,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
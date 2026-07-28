import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/Product_Provider.dart';
import '../shop/product_detail_screen.dart';

class SearchOverlay extends StatefulWidget {
  final VoidCallback onClose;
  const SearchOverlay({super.key, required this.onClose});

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<Product> _results(List<Product> allProducts) {
    if (_query.trim().isEmpty) return [];
    final q = _query.trim().toLowerCase();
    return allProducts.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
    }).toList();
  }

  int _discountPercent(double price, double original) =>
      (((original - price) / original) * 100).round();

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Electronics':
        return Icons.devices_rounded;
      case 'Fashion':
        return Icons.checkroom_rounded;
      case 'Home & Kitchen':
        return Icons.kitchen_rounded;
      case 'Sports':
        return Icons.sports_soccer_rounded;
      case 'Books':
        return Icons.menu_book_rounded;
      case 'Beauty':
        return Icons.face_retouching_natural_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  void _close() {
    _focus.unfocus();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final primaryBlue = Theme.of(context).colorScheme.primary;
    final darkText = Theme.of(context).colorScheme.onSurface;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);
    final cardWhite = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceGreen = isDark
        ? const Color(0xFF66BB6A)
        : const Color(0xFF2E7D32);
    const discountRed = Color(0xFFD32F2F);

    // Products come from provider — already fetched, no loading needed here
    final provider = context.watch<ProductProvider>();
    final allProducts = provider.products;
    final isLoading = provider.isLoading;
    final results = _results(allProducts);

    return Material(
      color: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            // ── Search bar ──────────────────────────────────────────
            Container(
              color: cardWhite,
              padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: darkText,
                    ),
                    onPressed: _close,
                  ),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: darkText,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search products…',
                          hintStyle: TextStyle(color: greyText, fontSize: 14),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: greyText,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: greyText.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: greyText,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Results ─────────────────────────────────────────────
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _query.trim().isEmpty
                  ? _buildEmptyState(
                      context: context,
                      icon: Icons.search_rounded,
                      title: 'Search QuickCart',
                      subtitle:
                          'Find products by name, category\nor description',
                    )
                  : results.isEmpty
                  ? _buildEmptyState(
                      context: context,
                      icon: Icons.search_off_rounded,
                      title: 'No results found',
                      subtitle:
                          'Try a different keyword\nor browse categories on Home',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 14, color: greyText),
                              children: [
                                TextSpan(
                                  text: '${results.length} ',
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const TextSpan(text: 'results for  "'),
                                TextSpan(
                                  text: _query.trim(),
                                  style: TextStyle(
                                    color: darkText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: '"'),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            itemCount: results.length,
                            itemBuilder: (context, index) => _buildResultTile(
                              results[index],
                              primaryBlue: primaryBlue,
                              darkText: darkText,
                              greyText: greyText,
                              bgColor: bgColor,
                              cardWhite: cardWhite,
                              priceGreen: priceGreen,
                              discountRed: discountRed,
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
  }

  Widget _buildEmptyState({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final primaryBlue = Theme.of(context).colorScheme.primary;
    final darkText = Theme.of(context).colorScheme.onSurface;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primaryBlue.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: primaryBlue.withAlpha(150)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: greyText, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(
    Product product, {
    required Color primaryBlue,
    required Color darkText,
    required Color greyText,
    required Color bgColor,
    required Color cardWhite,
    required Color priceGreen,
    required Color discountRed,
  }) {
    final discount = _discountPercent(product.price, product.originalPrice);
    final icon = _categoryIcon(product.category);

    return GestureDetector(
      onTap: () {
        _focus.unfocus();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
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
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: product.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Icon(
                            icon,
                            size: 32,
                            color: primaryBlue.withAlpha(120),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        icon,
                        size: 32,
                        color: primaryBlue.withAlpha(120),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: primaryBlue.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: darkText,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: priceGreen,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '₹${product.originalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: greyText,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (discount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: discountRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-$discount%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: greyText),
          ],
        ),
      ),
    );
  }
}

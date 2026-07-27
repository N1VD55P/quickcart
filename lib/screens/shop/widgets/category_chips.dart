import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../../models/product.dart';
import '../../../providers/Product_Provider.dart';
import '../product_detail_screen.dart';

const _discountRed = Color(0xFFD32F2F);

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer painter — draws a left-to-right gradient sweep over a base grey.
// ─────────────────────────────────────────────────────────────────────────────
class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({
    required this.progress,
    required this.baseColor,
    required this.highlightColor,
  });

  final double progress; // 0 → 1
  final Color baseColor;
  final Color highlightColor;

  @override
  void paint(Canvas canvas, Size size) {
    // The highlight band travels from -size.width to +2*size.width
    final double bandCenter = -size.width + progress * size.width * 3;

    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [baseColor, baseColor, highlightColor, baseColor, baseColor],
      stops: [
        0.0,
        (bandCenter - size.width * 0.3).clamp(0.0, 1.0) / size.width,
        (bandCenter).clamp(0.0, size.width) / size.width,
        (bandCenter + size.width * 0.3).clamp(0.0, size.width) / size.width,
        1.0,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer container — wraps any child with the animated overlay via ClipRect.
// ─────────────────────────────────────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});
  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFE0E0E0);
    final highlightColor = isDark
        ? const Color(0xFF3E3E3E)
        : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return ClipRect(
          child: CustomPaint(
            painter: _ShimmerPainter(
              progress: _anim.value,
              baseColor: baseColor,
              highlightColor: highlightColor,
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// A single skeleton card — mirrors the real card's layout exactly.
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFE0E0E0);
    final cardWhite = Theme.of(context).cardColor;

    Widget block({double? width, double? height, double radius = 6}) =>
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(radius),
          ),
        );

    return _Shimmer(
      child: Container(
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title line 1
                    block(width: double.infinity, height: 11),
                    const SizedBox(height: 6),
                    // Title line 2 (shorter)
                    block(width: 100, height: 11),
                    const Spacer(),
                    // Price
                    block(width: 64, height: 14),
                    const SizedBox(height: 5),
                    // Original price strikethrough
                    block(width: 44, height: 10),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton chip — mirrors the real category chip.
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonChip extends StatelessWidget {
  const _SkeletonChip({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFE0E0E0);
    final cardWhite = Theme.of(context).cardColor;

    return _Shimmer(
      child: Container(
        width: width,
        height: 36,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: width * 0.55,
            height: 10,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full skeleton state — chip row + 2-column grid of skeleton cards.
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonLoading extends StatelessWidget {
  const _SkeletonLoading();

  static const _chipWidths = [56.0, 80.0, 100.0, 72.0, 68.0, 76.0, 70.0];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Skeleton chip row
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _chipWidths.length,
            itemBuilder: (_, i) => _SkeletonChip(width: _chipWidths[i]),
          ),
        ),

        const SizedBox(height: 16),

        // "All Products" title placeholder
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _Shimmer(
            child: Container(
              width: 110,
              height: 14,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 2-column skeleton grid  (6 cards)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => const _SkeletonCard(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main widget
// ─────────────────────────────────────────────────────────────────────────────
class CategoryChips extends StatefulWidget {
  const CategoryChips({super.key});

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
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

  int _discountPercent(double price, double original) {
    if (original <= 0 || original <= price) return 0;
    return (((original - price) / original) * 100).round();
  }

  Future<void> _toggleWishlist(String productId) async {
    final box = Hive.box<String>('wishlist');
    dynamic existingKey;
    for (final k in box.keys) {
      if (box.get(k) == productId) {
        existingKey = k;
        break;
      }
    }
    if (existingKey != null) {
      await box.delete(existingKey);
    } else {
      await box.add(productId);
    }
  }

  bool _isWishlisted(Box<String> wishBox, String productId) =>
      wishBox.values.contains(productId);

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProductProvider>().isLoading;

    // ── While loading: show full skeleton ──────────────────────────────────
    if (isLoading) return const _SkeletonLoading();

    // ── Loaded: show real UI ───────────────────────────────────────────────
    final primaryBlue = Theme.of(context).colorScheme.primary;
    final darkText = Theme.of(context).colorScheme.onSurface;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);
    final cardWhite = Theme.of(context).cardColor;

    final allProducts = context.watch<ProductProvider>().products;
    final products = _selectedCategory == 'All'
        ? allProducts
        : allProducts.where((p) => p.category == _selectedCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Category chips ─────────────────────────────────────────────────
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryBlue : cardWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (cat != 'All') ...[
                        Icon(
                          _categoryIcon(cat),
                          size: 14,
                          color: isSelected ? Colors.white : greyText,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? Colors.white : greyText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _selectedCategory == 'All' ? 'All Products' : _selectedCategory,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
        ),

        const SizedBox(height: 12),

        if (products.isEmpty)
          SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: greyText.withAlpha(127),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No products found',
                    style: TextStyle(color: greyText, fontSize: 15),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) =>
                _buildProductCard(context, products[index]),
          ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final primaryBlue = Theme.of(context).colorScheme.primary;
    final darkText = Theme.of(context).colorScheme.onSurface;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);
    final cardWhite = Theme.of(context).cardColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceGreen = isDark
        ? const Color(0xFF66BB6A)
        : const Color(0xFF2E7D32);
    final shimmerBase = isDark
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFE0E0E0);

    final discount = _discountPercent(product.price, product.originalPrice);
    final categoryIcon = _categoryIcon(product.category);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image area ───────────────────────────────────────────────
            Stack(
              children: [
                Container(
                  height: 130,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: product.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: Image.network(
                            product.imageUrl,
                            width: double.infinity,
                            height: 130,
                            fit: BoxFit.cover,
                            // Grey shimmer while the image bytes arrive,
                            // so all cards feel uniform during network load.
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return _Shimmer(
                                child: Container(
                                  width: double.infinity,
                                  height: 130,
                                  color: shimmerBase,
                                ),
                              );
                            },
                            errorBuilder: (context, _, __) => Center(
                              child: Icon(
                                categoryIcon,
                                size: 56,
                                color: primaryBlue.withAlpha(76),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            categoryIcon,
                            size: 56,
                            color: primaryBlue.withAlpha(76),
                          ),
                        ),
                ),

                if (discount > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _discountRed,
                        borderRadius: BorderRadius.circular(6),
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
                  ),

                Positioned(
                  top: 8,
                  right: 8,
                  child: ValueListenableBuilder(
                    valueListenable: Hive.box<String>('wishlist').listenable(),
                    builder: (context, Box<String> wishBox, _) {
                      final wishlisted = _isWishlisted(wishBox, product.id);
                      return GestureDetector(
                        onTap: () => _toggleWishlist(product.id),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: cardWhite,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(25),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            wishlisted
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 16,
                            color: wishlisted ? Colors.red : greyText,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // ── Text / price area ────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: darkText,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: priceGreen,
                      ),
                    ),
                    Text(
                      '₹${product.originalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: greyText,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

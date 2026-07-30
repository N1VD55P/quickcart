import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../../providers/cart_provider.dart';
import '../../providers/Product_Provider.dart';
import 'cart_screen.dart';

const _discountRed = Color(0xFFD32F2F);

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _reviewController = TextEditingController();
  int _selectedRating = 0;
  bool _isSubmitting = false;
  //avoide
  bool _imageLoaded = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }


  int get _discountPercent {
    final o = widget.product.originalPrice;
    final p = widget.product.price;
    if (o <= 0 || o <= p) return 0;
    return (((o - p) / o) * 100).round();
  }

  IconData get _categoryIcon {
    switch (widget.product.category) {
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

  String get _currentUserEmail =>
      Hive.box('settings').get('currentUser', defaultValue: '');

  List<Review> get _productReviews {
    return Hive.box<Review>(
        'reviews',
      ).values.where((r) => r.productId == widget.product.id).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  double get _averageRating {
    final reviews = _productReviews;
    if (reviews.isEmpty) return 0;
    return reviews.map((r) => r.rating).reduce((a, b) => a + b) /
        reviews.length;
  }

  bool get _isWishlisted {
    final wishBox = Hive.box<String>('wishlist');
    return wishBox.values.contains(widget.product.id);
  }

  Future<void> _toggleWishlist() async {
    final wishBox = Hive.box<String>('wishlist');
    if (_isWishlisted) {
      dynamic key;
      for (final k in wishBox.keys) {
        if (wishBox.get(k) == widget.product.id) {
          key = k;
          break;
        }
      }
      if (key != null) await wishBox.delete(key);
    } else {
      await wishBox.add(widget.product.id);
    }
    setState(() {});
  }

  void _addToCart(BuildContext context) {
    final primaryBlue = Theme.of(context).colorScheme.primary;
    context.read<CartProvider>().addToCart(widget.product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} added to cart'),
        backgroundColor: primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      _showSnack('Please select a star rating', Colors.orange);
      return;
    }
    if (_reviewController.text.trim().isEmpty) {
      _showSnack('Please write a comment', Colors.orange);
      return;
    }
    setState(() => _isSubmitting = true);
    final review = Review(
      id: 'review_${DateTime.now().millisecondsSinceEpoch}',
      productId: widget.product.id,
      userEmail: _currentUserEmail,
      rating: _selectedRating,
      comment: _reviewController.text.trim(),
      dateTime: DateTime.now(),
    );
    await Hive.box<Review>('reviews').add(review);
    _reviewController.clear();
    setState(() {
      _selectedRating = 0;
      _isSubmitting = false;
    });
    if (mounted) _showSnack('Review submitted!', Colors.green);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Image: prefer ProductProvider cache, fall back to network ─────────────
  Widget _buildProductImage(Color primaryBlue, Color bgColor) {
    // Try to get product from provider (already cached)
    final cached = context
        .read<ProductProvider>()
        .products
        .where((p) => p.id == widget.product.id)
        .firstOrNull;

    final imageUrl =
        (cached?.imageUrl.isNotEmpty == true ? cached!.imageUrl : null) ??
        (widget.product.imageUrl.isNotEmpty ? widget.product.imageUrl : null);

    if (imageUrl == null) {
      return Center(
        child: Icon(_categoryIcon, size: 100, color: primaryBlue.withAlpha(60)),
      );
    }

    return Image.network(
      imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        // Show shimmer placeholder while loading
        return _ShimmerBox(width: double.infinity, height: double.infinity);
      },
      errorBuilder: (_, __, ___) => Center(
        child: Icon(_categoryIcon, size: 100, color: primaryBlue.withAlpha(60)),
      ),
    );
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
    final p = widget.product;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ── Hero image app bar ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: primaryBlue,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
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
            actions: [
              // Wishlist toggle in app bar
              ValueListenableBuilder(
                valueListenable: Hive.box<String>('wishlist').listenable(),
                builder: (context, _, __) => GestureDetector(
                  onTap: _toggleWishlist,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(38),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isWishlisted
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _isWishlisted ? Colors.red : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background color
                  Container(color: cardWhite),
                  // Product image
                  _buildProductImage(primaryBlue, bgColor),
                  // Discount badge
                  if (_discountPercent > 0)
                    Positioned(
                      top: 100,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _discountRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-$_discountPercent%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  // Bottom fade so text below reads cleanly
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [cardWhite, cardWhite.withAlpha(0)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Product info card ─────────────────────────────────────
                Container(
                  color: cardWhite,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryBlue.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.category,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Name
                      Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: darkText,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Rating row
                      ValueListenableBuilder(
                        valueListenable: Hive.box<Review>(
                          'reviews',
                        ).listenable(),
                        builder: (context, box, _) {
                          final avg = _averageRating;
                          final count = _productReviews.length;
                          return Row(
                            children: [
                              ...List.generate(
                                5,
                                (i) => Icon(
                                  i < avg.round()
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                avg > 0
                                    ? '${avg.toStringAsFixed(1)} ($count reviews)'
                                    : 'No reviews yet',
                                style: TextStyle(fontSize: 13, color: greyText),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Price row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${p.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: priceGreen,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              '₹${p.originalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                color: greyText,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                          if (_discountPercent > 0) ...[
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                '$_discountPercent% off',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: _discountRed,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Stock pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (p.stock > 0 ? Colors.green : Colors.red)
                              .withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: p.stock > 0 ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              p.stock > 0
                                  ? 'In Stock (${p.stock} left)'
                                  : 'Out of Stock',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: p.stock > 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Description ───────────────────────────────────────────
                Container(
                  color: cardWhite,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Description', darkText),
                      const SizedBox(height: 10),
                      Text(
                        p.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: greyText,
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Reviews ───────────────────────────────────────────────
                Container(
                  color: cardWhite,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Reviews', darkText),
                      const SizedBox(height: 16),

                      // Write review
                      Text(
                        'Write a Review',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Star picker
                      Row(
                        children: List.generate(
                          5,
                          (i) => GestureDetector(
                            onTap: () =>
                                setState(() => _selectedRating = i + 1),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                i < _selectedRating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: Colors.amber,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Comment field
                      TextFormField(
                        controller: _reviewController,
                        maxLines: 3,
                        style: TextStyle(color: darkText, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Share your experience...',
                          hintStyle: TextStyle(color: greyText, fontSize: 14),
                          filled: true,
                          fillColor: bgColor,
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitReview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Submit Review',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Review list
                      ValueListenableBuilder(
                        valueListenable: Hive.box<Review>(
                          'reviews',
                        ).listenable(),
                        builder: (context, box, _) {
                          final reviews = _productReviews;
                          if (reviews.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Text(
                                  'No reviews yet. Be the first!',
                                  style: TextStyle(
                                    color: greyText.withAlpha(180),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: reviews
                                .map((r) => _buildReviewTile(context, r))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Space for bottom bar
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

      // ── Bottom bar ──────────────────────────────────────────────────────
      bottomNavigationBar: Container(
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
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${p.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: priceGreen,
                    ),
                  ),
                  Text(
                    '₹${p.originalPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: greyText,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: p.stock > 0 ? () => _addToCart(context) : null,
                    icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                    label: Text(
                      p.stock > 0 ? 'Add to Cart' : 'Out of Stock',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: greyText,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, Color darkText) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: darkText,
      ),
    );
  }

  Widget _buildReviewTile(BuildContext context, Review review) {
    final primaryBlue = Theme.of(context).colorScheme.primary;
    final darkText = Theme.of(context).colorScheme.onSurface;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: primaryBlue.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review.userEmail.isNotEmpty
                        ? review.userEmail[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: darkText,
                      ),
                    ),
                    Text(
                      '${review.dateTime.day}/${review.dateTime.month}/${review.dateTime.year}',
                      style: TextStyle(fontSize: 11, color: greyText),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: TextStyle(fontSize: 13, color: greyText, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer placeholder ───────────────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  const _ShimmerBox({required this.width, required this.height});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final highlight = isDark
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}

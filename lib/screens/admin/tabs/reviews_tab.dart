import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/review.dart';

class ReviewsTab extends StatefulWidget {
  const ReviewsTab({super.key});

  @override
  State<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _ratingFilter = 0; // 0 = All
  Map<String, String> _productNames = {}; // productId -> name

  @override
  void initState() {
    super.initState();
    _loadProductNames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProductNames() async {
    final snap =
        await FirebaseFirestore.instance.collection('products').get();
    if (mounted) {
      setState(() {
        _productNames = {
          for (final d in snap.docs)
            (d.data()['id'] as String? ?? d.id):
                (d.data()['name'] as String? ?? d.id)
        };
      });
    }
  }

  List<Review> _filtered(List<Review> all) {
    var list = all;

    if (_ratingFilter > 0) {
      list = list.where((r) => r.rating == _ratingFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) {
        return r.userEmail.toLowerCase().contains(q) ||
            r.productId.toLowerCase().contains(q) ||
            (_productNames[r.productId] ?? '')
                .toLowerCase()
                .contains(q);
      }).toList();
    }

    // Newest first
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _deleteReview(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Review',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(
            'Are you sure you want to delete this review?'),
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
    if (confirmed == true) await review.delete();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Review>('reviews').listenable(),
      builder: (context, Box<Review> box, _) {
        final all = box.values.toList();
        final filtered = _filtered(all);

        // Stats from all reviews (not filtered)
        final totalReviews = all.length;
        final avgRating = totalReviews == 0
            ? 0.0
            : all.fold(0, (sum, r) => sum + r.rating) / totalReviews;

        return Column(
          children: [
            // ── Summary ───────────────────────────────────────────
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
                  Expanded(
                    child: Column(
                      children: [
                        Text('$totalReviews',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87)),
                        const SizedBox(height: 2),
                        const Text('Total Reviews',
                            style: TextStyle(
                                fontSize: 11, color: Colors.black45)),
                      ],
                    ),
                  ),
                  Container(
                      width: 1, height: 36, color: Colors.grey.shade200),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              avgRating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text('Avg Rating',
                            style: TextStyle(
                                fontSize: 11, color: Colors.black45)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Search bar ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by email or product…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
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
                onChanged: (v) =>
                    setState(() => _searchQuery = v.trim()),
              ),
            ),

            // ── Rating filter ─────────────────────────────────────
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _RatingChip(
                    label: 'All',
                    selected: _ratingFilter == 0,
                    onTap: () => setState(() => _ratingFilter = 0),
                  ),
                  for (int r = 5; r >= 1; r--)
                    _RatingChip(
                      label: '$r ★',
                      selected: _ratingFilter == r,
                      onTap: () => setState(() => _ratingFilter = r),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ── Review list ───────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('No reviews found',
                          style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final review = filtered[i];
                        final productName =
                            _productNames[review.productId] ??
                                review.productId;
                        return Dismissible(
                          key: ValueKey(review.id),
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
                            await _deleteReview(review);
                            return false; // Hive handles the rebuild
                          },
                          child: _ReviewTile(
                            review: review,
                            productName: productName,
                            formattedDate:
                                _formatDate(review.dateTime),
                            onDelete: () => _deleteReview(review),
                          ),
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

// ── Review tile ───────────────────────────────────────────────────────────────

class _ReviewTile extends StatelessWidget {
  final Review review;
  final String productName;
  final String formattedDate;
  final VoidCallback onDelete;

  const _ReviewTile({
    required this.review,
    required this.productName,
    required this.formattedDate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue.shade50,
                child: Text(
                  review.userEmail.isNotEmpty
                      ? review.userEmail[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue.shade600),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userEmail,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(productName,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black45),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // Delete button
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 16, color: Colors.red),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Stars + date ─────────────────────────────────────
          Row(
            children: [
              // Stars
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: Colors.amber,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text('${review.rating}/5',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54)),
              const Spacer(),
              Text(formattedDate,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.black38)),
            ],
          ),

          // ── Comment ──────────────────────────────────────────
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment,
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4)),
          ],
        ],
      ),
    );
  }
}

// ── Rating chip ───────────────────────────────────────────────────────────────

class _RatingChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RatingChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.amber.shade700 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.amber.shade700
                : Colors.grey.shade300,
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
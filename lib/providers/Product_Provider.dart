import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// All unique categories derived from loaded products.
  List<String> get categories {
    final cats = _products.map((p) => p.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  /// Filter products by category. Returns all if 'All' is selected.
  List<Product> byCategory(String category) {
    if (category == 'All') return _products;
    return _products.where((p) => p.category == category).toList();
  }

  /// Search products by name, description, or category.
  List<Product> search(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.trim().toLowerCase();
    return _products.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
    }).toList();
  }

  /// Fetch products from Firestore once. Safe to call multiple times —
  /// skips if already loaded.
  Future<void> fetchProducts({bool force = false}) async {
    if (_products.isNotEmpty && !force) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snap = await FirebaseFirestore.instance
          .collection('products')
          .get();

      _products = snap.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: data['id'] as String? ?? doc.id,
          name: data['name'] as String? ?? '',
          price: (data['price'] as num).toDouble(),
          originalPrice: (data['originalPrice'] as num).toDouble(),
          imageUrl: data['imageUrl'] as String? ?? '',
          description: data['description'] as String? ?? '',
          category: data['category'] as String? ?? '',
          stock: (data['stock'] as num).toInt(),
        );
      }).toList();

      _error = null;
    } catch (e) {
      _error = 'Failed to load products. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

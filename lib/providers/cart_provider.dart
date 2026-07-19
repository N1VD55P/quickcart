import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  Box<CartItem> get _box => Hive.box<CartItem>('cart');

  List<CartItem> get items => _box.values.toList();

  int get itemCount => _box.length;

  double get total =>
      items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  Future<void> addToCart(Product product) async {
    final existing = _box.values.cast<CartItem?>().firstWhere(
      (item) => item?.productId == product.id,
      orElse: () => null,
    );

    if (existing != null) {
      existing.quantity += 1;
      await existing.save();
    } else {
      await _box.add(
        CartItem(
          productId: product.id,
          name: product.name,
          price: product.price,
          imageUrl: product.imageUrl,
          category: product.category,
          quantity: 1,
        ),
      );
    }
    notifyListeners();
  }

  Future<void> increaseQty(CartItem item) async {
    item.quantity += 1;
    await item.save();
    notifyListeners();
  }

  Future<void> decreaseQty(CartItem item) async {
    if (item.quantity <= 1) {
      await item.delete();
    } else {
      item.quantity -= 1;
      await item.save();
    }
    notifyListeners();
  }

  Future<void> removeItem(CartItem item) async {
    await item.delete();
    notifyListeners();
  }

  Future<void> clearCart() async {
    await _box.clear();
    notifyListeners();
  }
}

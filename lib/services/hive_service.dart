import 'package:hive_flutter/hive_flutter.dart';

import '../models/address.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../models/user.dart';

class HiveService {
  static Box<User> get users => Hive.box<User>('users');

  static Box<Product> get products => Hive.box<Product>('products');

  static Box<CartItem> get cart => Hive.box<CartItem>('cart');

  static Box<Order> get orders => Hive.box<Order>('orders');

  static Box<Address> get addresses => Hive.box<Address>('addresses');

  static Box<Review> get reviews => Hive.box<Review>('reviews');

  static Box get settings => Hive.box('settings');

  static Box<Product> get wishlist => Hive.box<Product>('wishlist');
}
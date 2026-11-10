import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:quickcart/models/cart_item.dart';
import 'package:quickcart/models/order.dart';
import 'package:quickcart/models/product.dart';
import 'package:quickcart/models/user.dart';
import 'package:quickcart/providers/cart_provider.dart';
import 'package:quickcart/providers/profile_provider.dart';
import 'package:quickcart/providers/theme_provider.dart';
import 'package:quickcart/services/auth_service.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('cartify_test_');
    Hive.init(hiveDirectory.path);
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(CartItemAdapter());
    Hive.registerAdapter(OrderAdapter());
    await Hive.openBox<User>('users');
    await Hive.openBox<CartItem>('cart');
    await Hive.openBox<Order>('orders');
    await Hive.openBox('settings');
  });

  setUp(() async {
    await Hive.box<User>('users').clear();
    await Hive.box<CartItem>('cart').clear();
    await Hive.box<Order>('orders').clear();
    await Hive.box('settings').clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  User createUser(String email) => User(
    name: 'Test User',
    email: email,
    passwordHash: '',
    phone: '',
    securityAnswer: 'answer',
  );

  CartItem createCartItem({
    required String productId,
    required String userEmail,
    int quantity = 1,
  }) => CartItem(
    productId: productId,
    name: 'Test Product',
    price: 100,
    imageUrl: '',
    quantity: quantity,
    category: 'Test',
    userEmail: userEmail,
  );

  group('Local authentication', () {
    test('signup hashes the password and login stores the session', () {
      final service = AuthService();
      final user = createUser('user@example.com');
      user.passwordHash = 'password123';

      expect(service.signup(user), isTrue);
      expect(user.passwordHash, isNot('password123'));
      expect(service.login('user@example.com', 'password123'), isTrue);
      expect(service.currentUserEmail(), equals('user@example.com'));
      expect(service.isLoggedIn(), isTrue);
    });

    test('duplicate email is rejected', () {
      final service = AuthService();
      final first = createUser('user@example.com')..passwordHash = 'one123';
      final second = createUser('user@example.com')..passwordHash = 'two123';

      expect(service.signup(first), isTrue);
      expect(service.signup(second), isFalse);
    });
  });

  group('User-scoped cart persistence', () {
    test('cart totals include only the active user', () async {
      final cartBox = Hive.box<CartItem>('cart');
      await cartBox.add(
        createCartItem(productId: 'p1', userEmail: 'a@example.com'),
      );
      await cartBox.add(
        createCartItem(
          productId: 'p2',
          userEmail: 'b@example.com',
          quantity: 2,
        ),
      );
      await Hive.box('settings').put('currentUser', 'a@example.com');

      final provider = CartProvider();

      expect(provider.items, hasLength(1));
      expect(provider.itemCount, equals(1));
      expect(provider.total, equals(100));
    });

    test(
      'adding the same product increments only the active user item',
      () async {
        await Hive.box('settings').put('currentUser', 'a@example.com');
        final provider = CartProvider();
        final product = ProductFixture.product;

        await provider.addToCart(product);
        await provider.addToCart(product);

        expect(provider.items, hasLength(1));
        expect(provider.items.single.quantity, equals(2));
      },
    );

    test('clearCart removes only the active user items', () async {
      final cartBox = Hive.box<CartItem>('cart');
      await cartBox.add(
        createCartItem(productId: 'p1', userEmail: 'a@example.com'),
      );
      await cartBox.add(
        createCartItem(productId: 'p2', userEmail: 'b@example.com'),
      );
      await Hive.box('settings').put('currentUser', 'a@example.com');

      await CartProvider().clearCart();

      expect(cartBox.values, hasLength(1));
      expect(cartBox.values.single.userEmail, equals('b@example.com'));
    });
  });

  group('Profile and theme persistence', () {
    test('profile provider loads and updates the active user', () async {
      final user = createUser('user@example.com');
      await Hive.box<User>('users').add(user);
      await Hive.box('settings').put('currentUser', 'user@example.com');

      final provider = ProfileProvider()..loadUser();
      await provider.updateProfile('Updated User', '9876543210');

      expect(provider.userName, equals('Updated User'));
      expect(provider.userPhone, equals('9876543210'));
      expect(
        Hive.box<User>('users').values.single.name,
        equals('Updated User'),
      );
    });

    test('theme choice persists in settings', () {
      final provider = ThemeProvider();

      expect(provider.isDarkMode, isFalse);
      provider.toggleTheme();

      expect(provider.isDarkMode, isTrue);
      expect(Hive.box('settings').get('isDarkMode'), isTrue);
    });
  });
}

class ProductFixture {
  static Product get product => Product(
    id: 'p1',
    name: 'Test Product',
    price: 100,
    originalPrice: 100,
    imageUrl: '',
    description: 'Test description',
    category: 'Test',
    stock: 5,
  );
}

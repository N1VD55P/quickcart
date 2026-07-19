import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/address.dart';
import 'models/cart_item.dart';
import 'models/order.dart';
import 'models/product.dart';
import 'models/review.dart';
import 'models/user.dart';
import 'screens/auth/splash_screen.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();

  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(CartItemAdapter());
  Hive.registerAdapter(OrderAdapter());
  Hive.registerAdapter(AddressAdapter());
  Hive.registerAdapter(ReviewAdapter());

  await Hive.openBox<User>('users');
  await Hive.openBox<Product>('products');
  await Hive.openBox<CartItem>('cart');
  await Hive.openBox<Order>('orders');
  await Hive.openBox<Address>('addresses');
  await Hive.openBox<Review>('reviews');
  await Hive.openBox('settings');
  await Hive.openBox<String>('wishlist');

  await _seedProducts();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const QuickCartApp(),
    ),
  );
}

Future<void> _seedProducts() async {
  final box = Hive.box<Product>('products');
  if (box.isNotEmpty) return;
  const products = [
    {
      'id': 'product_0',
      'name': 'Wireless Earbuds',
      'price': 1299.0,
      'originalPrice': 2199.0,
      'category': 'Electronics',
      'description': 'True wireless stereo earbuds with 24hr battery life.',
      'stock': 15,
      'imageUrl': '',
    },
    {
      'id': 'product_1',
      'name': 'Smart Watch',
      'price': 2499.0,
      'originalPrice': 3999.0,
      'category': 'Electronics',
      'description': 'Fitness tracker with heart rate monitor and GPS.',
      'stock': 10,
      'imageUrl': '',
    },
    {
      'id': 'product_2',
      'name': 'Running Shoes',
      'price': 1899.0,
      'originalPrice': 2499.0,
      'category': 'Sports',
      'description': 'Lightweight running shoes with cushioned sole.',
      'stock': 20,
      'imageUrl': '',
    },
    {
      'id': 'product_3',
      'name': 'Cotton Kurta',
      'price': 599.0,
      'originalPrice': 999.0,
      'category': 'Fashion',
      'description': 'Premium cotton kurta with traditional embroidery.',
      'stock': 30,
      'imageUrl': '',
    },
    {
      'id': 'product_4',
      'name': 'Non-stick Cookware Set',
      'price': 1499.0,
      'originalPrice': 2299.0,
      'category': 'Home & Kitchen',
      'description': '5-piece non-stick cookware set.',
      'stock': 8,
      'imageUrl': '',
    },
    {
      'id': 'product_5',
      'name': 'Vitamin C Serum',
      'price': 449.0,
      'originalPrice': 699.0,
      'category': 'Beauty',
      'description': 'Brightening vitamin C serum with hyaluronic acid.',
      'stock': 25,
      'imageUrl': '',
    },
    {
      'id': 'product_6',
      'name': 'Atomic Habits',
      'price': 349.0,
      'originalPrice': 499.0,
      'category': 'Books',
      'description': 'James Clear\'s #1 bestseller on building good habits.',
      'stock': 50,
      'imageUrl': '',
    },
    {
      'id': 'product_7',
      'name': 'Bluetooth Speaker',
      'price': 999.0,
      'originalPrice': 1599.0,
      'category': 'Electronics',
      'description': 'Portable waterproof speaker with 360 surround sound.',
      'stock': 12,
      'imageUrl': '',
    },
    {
      'id': 'product_8',
      'name': 'Yoga Mat',
      'price': 699.0,
      'originalPrice': 999.0,
      'category': 'Sports',
      'description': 'Anti-slip 6mm thick yoga mat with carry strap.',
      'stock': 18,
      'imageUrl': '',
    },
    {
      'id': 'product_9',
      'name': 'Face Moisturizer',
      'price': 299.0,
      'originalPrice': 450.0,
      'category': 'Beauty',
      'description': 'Lightweight daily moisturizer with SPF 30.',
      'stock': 40,
      'imageUrl': '',
    },
    {
      'id': 'product_10',
      'name': 'Denim Jacket',
      'price': 1199.0,
      'originalPrice': 1799.0,
      'category': 'Fashion',
      'description': 'Classic slim-fit denim jacket. Unisex design.',
      'stock': 14,
      'imageUrl': '',
    },
    {
      'id': 'product_11',
      'name': 'Air Fryer',
      'price': 3299.0,
      'originalPrice': 4999.0,
      'category': 'Home & Kitchen',
      'description': '4.5L digital air fryer with 8 preset modes.',
      'stock': 6,
      'imageUrl': '',
    },
  ];

  for (final p in products) {
    await box.add(
      Product(
        id: p['id'] as String,
        name: p['name'] as String,
        price: p['price'] as double,
        originalPrice: p['originalPrice'] as double,
        imageUrl: p['imageUrl'] as String,
        description: p['description'] as String,
        category: p['category'] as String,
        stock: p['stock'] as int,
      ),
    );
  }
}

class QuickCartApp extends StatelessWidget {
  const QuickCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'QuickCart',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          theme: ThemeData(
            colorSchemeSeed: Colors.blue,
            brightness: Brightness.light,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.blue,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

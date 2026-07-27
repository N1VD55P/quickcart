import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/address.dart';
import 'models/cart_item.dart';
import 'models/order.dart';
import 'models/review.dart';
import 'models/user.dart';
import 'screens/auth/splash_screen.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/Product_Provider.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();

  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(CartItemAdapter());
  Hive.registerAdapter(OrderAdapter());
  Hive.registerAdapter(AddressAdapter());
  Hive.registerAdapter(ReviewAdapter());

  await Hive.openBox<User>('users');
  await Hive.openBox<CartItem>('cart');
  await Hive.openBox<Order>('orders');
  await Hive.openBox<Address>('addresses');
  await Hive.openBox<Review>('reviews');
  await Hive.openBox('settings');
  await Hive.openBox<String>('wishlist');

  // Fetch products once before the app starts so every screen
  // that reads ProductProvider already has data on first build.
  final productProvider = ProductProvider();
  await productProvider.fetchProducts();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Use .value so we pass the already-loaded instance
        ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
      ],
      child: const QuickCartApp(),
    ),
  );
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

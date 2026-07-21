import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quickcart/models/user.dart';
import 'widgets/banner_slider.dart';
import 'widgets/category_chips.dart';
import 'cart_screen.dart';
import '../../screens/profile/profile_screen.dart';
import 'wishlist_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentNavIndex = 0;
  bool _searchVisible = false;
  AnimationController? _searchAnim;
  Animation<Offset>? _slideAnim;

  @override
  void initState() {
    super.initState();
    _searchAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _searchAnim!,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
  }

  @override
  void dispose() {
    _searchAnim?.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searchVisible = true);
    _searchAnim?.forward();
  }

  void _closeSearch() {
    _searchAnim?.reverse().then((_) {
      if (mounted) setState(() => _searchVisible = false);
    });
  }

  String get _userName {
    final settings = Hive.box('settings');
    final email = settings.get('currentUser', defaultValue: '');
    if (email.isEmpty) return 'there';
    final usersBox = Hive.box<User>('users');
    final matches = usersBox.values.where((u) => u.email == email);
    if (matches.isEmpty) return 'there';
    return matches.first.name.split(' ').first;
  }

  Widget _buildHomeTab(BuildContext context) {
    final darkText = Theme.of(context).colorScheme.onSurface;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: darkText,
                          letterSpacing: -0.3,
                        ),
                        children: [
                          TextSpan(text: 'Hey, $_userName\n'),
                          TextSpan(
                            text: 'What are you looking for?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: greyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const BannerSlider(),
                  const SizedBox(height: 20),
                  const CategoryChips(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentNavIndex,
            children: [
              const SizedBox.shrink(),
              ProfileScreen(onBack: () => setState(() => _currentNavIndex = 0)),
              const SizedBox.shrink(),
              const WishlistScreen(),
              const CartScreen(),
            ],
          ),

          if (_currentNavIndex == 0) _buildHomeTab(context),

          if (_searchVisible && _slideAnim != null)
            SlideTransition(
              position: _slideAnim!,
              child: SearchOverlay(onClose: _closeSearch),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final cardWhite = Theme.of(context).cardColor;
    const primaryBlue = Color(0xFF1565C0);

    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  _navItem(context, 0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                  _navItem(context, 1, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
                  const Expanded(child: SizedBox()),
                  _navItem(context, 3, Icons.favorite_border_rounded, Icons.favorite_rounded, 'Wishlist'),
                  _navItem(context, 4, Icons.shopping_cart_outlined, Icons.shopping_cart_rounded, 'Cart'),
                ],
              ),

              Positioned(
                top: -16,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _openSearch,
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withAlpha(100),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _searchVisible
                            ? Icons.search_rounded
                            : Icons.search_outlined,
                        color: Colors.white,
                        size: 26,
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

  Widget _navItem(
    BuildContext context,
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final primaryBlue = Theme.of(context).colorScheme.primary;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);
    final isActive = !_searchVisible && _currentNavIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_searchVisible) _closeSearch();
          setState(() => _currentNavIndex = index);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? primaryBlue : greyText,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? primaryBlue : greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
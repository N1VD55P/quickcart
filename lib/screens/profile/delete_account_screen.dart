import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/user.dart';
import '../../models/order.dart';
import '../../models/address.dart';
import '../../models/review.dart';
import '../../utils/password_helper.dart';
import '../auth/login_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  String get _userEmail =>
      Hive.box('settings').get('currentUser', defaultValue: '');

  User? get _user {
    final matches = Hive.box<User>('users').values.where((u) => u.email == _userEmail);
    return matches.isEmpty ? null : matches.first;
  }

  Future<void> _deleteAccount() async {
    final errorColor = Theme.of(context).colorScheme.error;
    final user = _user;
    if (user == null) return;

    if (PasswordHelper.hashPassword(_passwordController.text) != user.passwordHash) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Incorrect password'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final ordersBox = Hive.box<Order>('orders');
    for (final o in ordersBox.values.where((o) => o.userEmail == _userEmail).toList()) {
      await o.delete();
    }

    final addressBox = Hive.box<Address>('addresses');
    for (final a in addressBox.values.where((a) => a.userEmail == _userEmail).toList()) {
      await a.delete();
    }

    final reviewBox = Hive.box<Review>('reviews');
    for (final r in reviewBox.values.where((r) => r.userEmail == _userEmail).toList()) {
      await r.delete();
    }

    await Hive.box('cart').clear();
    await Hive.box('wishlist').clear();
    await user.delete();
    await Hive.box('settings').delete('currentUser');

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _confirmDelete() {
    final errorColor = Theme.of(context).colorScheme.error;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your password to confirm'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.red)),
        content: const Text(
          'This cannot be undone.\n\nYour account, orders, addresses and reviews will be permanently deleted.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: greyText)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
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

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.white.withAlpha(38), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Delete Account', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.withAlpha(60)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
                              SizedBox(width: 8),
                              Text('This cannot be undone',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.red)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...[
                            'Your account and login access',
                            'All your past orders',
                            'All saved addresses',
                            'All your product reviews',
                          ].map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.remove_circle_outline_rounded, color: Colors.red, size: 14),
                                    const SizedBox(width: 8),
                                    Text(item, style: const TextStyle(fontSize: 13, color: Colors.red)),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    Text('Enter your password to confirm',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: darkText)),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      style: TextStyle(color: darkText, fontSize: 15, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        labelStyle: TextStyle(color: greyText, fontSize: 14),
                        prefixIcon: Icon(Icons.lock_outline_rounded, color: greyText, size: 20),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _showPassword = !_showPassword),
                          child: Icon(
                            _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: greyText, size: 20,
                          ),
                        ),
                        filled: true,
                        fillColor: cardWhite,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _confirmDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Delete My Account', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: greyText,
                          side: BorderSide(color: greyText.withAlpha(100)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      ),
                    ),
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
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/user.dart';
import '../../utils/password_helper.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  User? get _user {
    final email = Hive.box('settings').get('currentUser', defaultValue: '');
    final matches = Hive.box<User>('users').values.where((u) => u.email == email);
    return matches.isEmpty ? null : matches.first;
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final errorColor = Theme.of(context).colorScheme.error;
    final user = _user;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    if (PasswordHelper.hashPassword(_currentController.text) != user.passwordHash) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Current password is incorrect'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    user.passwordHash = PasswordHelper.hashPassword(_newController.text);
    await user.save();

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password changed successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Widget _buildField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isVisible,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    final darkText = Theme.of(context).colorScheme.onSurface;
    final greyText = Theme.of(context).colorScheme.onSurface.withAlpha(150);
    final fieldFill = Theme.of(context).cardColor;
    final errorColor = Theme.of(context).colorScheme.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        validator: validator,
        textInputAction: textInputAction,
        style: TextStyle(color: darkText, fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          labelStyle: TextStyle(color: greyText, fontSize: 14),
          prefixIcon: Icon(icon, color: greyText, size: 20),
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(
              isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: greyText, size: 20,
            ),
          ),
          filled: true,
          fillColor: fieldFill,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: errorColor, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: errorColor, width: 1.5)),
          errorStyle: TextStyle(color: errorColor, fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final primaryBlue = Theme.of(context).colorScheme.primary;

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
                  const Text('Change Password', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: primaryBlue.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: primaryBlue, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('We verify your current password first.',
                                  style: TextStyle(fontSize: 13, color: primaryBlue)),
                            ),
                          ],
                        ),
                      ),
                      _buildField(
                        context: context,
                        controller: _currentController,
                        label: 'Current Password',
                        icon: Icons.lock_outline_rounded,
                        isVisible: _showCurrent,
                        onToggle: () => setState(() => _showCurrent = !_showCurrent),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter your current password' : null,
                      ),
                      _buildField(
                        context: context,
                        controller: _newController,
                        label: 'New Password',
                        icon: Icons.lock_outline_rounded,
                        isVisible: _showNew,
                        onToggle: () => setState(() => _showNew = !_showNew),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter a new password';
                          if (v.length < 6) return 'Minimum 6 characters';
                          return null;
                        },
                      ),
                      _buildField(
                        context: context,
                        controller: _confirmController,
                        label: 'Confirm New Password',
                        icon: Icons.lock_outline_rounded,
                        isVisible: _showConfirm,
                        onToggle: () => setState(() => _showConfirm = !_showConfirm),
                        textInputAction: TextInputAction.done,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please confirm your password';
                          if (v != _newController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Text('Update Password', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
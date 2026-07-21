import 'package:flutter/material.dart';
import 'package:quickcart/utils/validators.dart';
import 'package:quickcart/utils/password_helper.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quickcart/models/user.dart';
const _bgColor = Color(0xFFFFF8F3);
const _brandAccent = Colors.blue;
const _brandDeep = Color(0xFF1A1A2E);
const _fieldFill = Color(0xFFF5F5F8);
const _labelColor = Color(0xFF8B8FA8);
const _errorColor = Color(0xFFE53935);

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _securityAnswerController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Passwords do not match"),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final usersBox = Hive.box<User>('users');

    final exists = usersBox.values.any(
      (u) => u.email.trim().toLowerCase() ==
          _emailController.text.trim().toLowerCase(),
    );

    if (exists) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Email already registered"),
            backgroundColor: _errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    final user = User(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      passwordHash: PasswordHelper.hashPassword(_passwordController.text),
      phone: '',
      securityAnswer: _securityAnswerController.text.trim().toLowerCase(),
    );
    await usersBox.add(user);

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Account created successfully!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }

  
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    bool hasToggle = false,
    bool isVisible = false,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure && !isVisible,
        keyboardType: keyboardType,
        validator: validator,
        textInputAction: textInputAction,
        style: const TextStyle(
          color: _brandDeep,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          labelStyle: const TextStyle(color: _labelColor, fontSize: 14),
          prefixIcon: Icon(icon, color: _labelColor, size: 20),
          suffixIcon: hasToggle
              ? GestureDetector(
                  onTap: onToggle,
                  child: Icon(
                    isVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _labelColor,
                    size: 20,
                  ),
                )
              : null,
          filled: true,
          fillColor: _fieldFill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _errorColor, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _errorColor, width: 1.8),
          ),
          errorStyle: const TextStyle(color: _errorColor, fontSize: 12),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: _brandAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: _labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Row(
                  children: [
                    Container(
                      width: 58,
                      height:58,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.shopping_cart,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: _brandDeep,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(text: "Create your\n"),
                          TextSpan(
                            text: "QuickCart ",
                            style: TextStyle(color: _brandAccent),
                          ),
                          TextSpan(text: "account"),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                _sectionLabel("Personal Info"),
                const SizedBox(height: 12),

                _buildField(
                  controller: _nameController,
                  label: "Full Name",
                  icon: Icons.person_outline_rounded,
                  validator: Validators.validateName,
                ),

                _buildField(
                  controller: _emailController,
                  label: "Email Address",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),

                const SizedBox(height: 8),

                _sectionLabel("Security"),
                const SizedBox(height: 12),

                _buildField(
                  controller: _passwordController,
                  label: "Password",
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                  hasToggle: true,
                  isVisible: _showPassword,
                  onToggle: () =>
                      setState(() => _showPassword = !_showPassword),
                  validator: Validators.validatePassword,
                ),

                _buildField(
                  controller: _confirmPasswordController,
                  label: "Confirm Password",
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                  hasToggle: true,
                  isVisible: _showConfirmPassword,
                  onToggle: () => setState(
                    () => _showConfirmPassword = !_showConfirmPassword,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Please confirm your password";
                    if (v != _passwordController.text) return "Passwords do not match";
                    return null;
                  },
                ),

                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _brandAccent.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _brandAccent.withAlpha(40),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.shield_outlined,
                            color: _brandAccent,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "SECURITY QUESTION",
                            style: TextStyle(
                              color: _brandAccent,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Your first school's name?",
                        style: TextStyle(
                          color: _brandDeep,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _securityAnswerController,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(
                          color: _brandDeep,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? "Please enter your security answer"
                            : null,
                        decoration: InputDecoration(
                          hintText: "Type your answer…",
                          hintStyle: const TextStyle(
                            color: _labelColor,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.edit_outlined,
                            color: _labelColor,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: _brandAccent,
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: _errorColor,
                              width: 1.5,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: _errorColor,
                              width: 1.5,
                            ),
                          ),
                          errorStyle: const TextStyle(
                            color: _errorColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandAccent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _brandAccent.withAlpha(153),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "Create Account",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 14, color: _labelColor),
                        children: [
                          TextSpan(text: "Already have an account? "),
                          TextSpan(
                            text: "Login",
                            style: TextStyle(
                              color: _brandAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:quickcart/utils/validators.dart';

import '../../models/user.dart';
import '../../utils/password_helper.dart';
import 'package:hive_flutter/hive_flutter.dart';
 
const _bgColor = Color(0xFFFFF8F3);
const _brandAccent = Colors.blue;
const _brandDeep = Color(0xFF1A1A2E);
const _fieldFill = Color(0xFFF5F5F8);
const _labelColor = Color(0xFF8B8FA8);
const _errorColor = Color(0xFFE53935);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 1;

   User? _foundUser;

  final _emailController = TextEditingController();
  final _answerController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailFormKey = GlobalKey<FormState>();
  final _answerFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _answerController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _findAccount() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final usersBox = Hive.box<User>('users');
    final matches = usersBox.values.where(
      (u) =>
          u.email.trim().toLowerCase() ==
          _emailController.text.trim().toLowerCase(),
    );
    if (matches.isEmpty) {
      setState(() => _isLoading = false);
      _showError("Details don't match. Please try again.");
      return;
    }
    _foundUser = matches.first;

    setState(() {
      _isLoading = false;
      _step = 2;
    });
  }

  Future<void> _verifyAnswer() async {
    if (!_answerFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final enteredAnswer = _answerController.text.trim().toLowerCase();
    final storedAnswer = _foundUser!.securityAnswer.trim().toLowerCase();
    if (enteredAnswer != storedAnswer) {
      setState(() => _isLoading = false);
      _showError("Details don't match. Please try again.");
      return;
    }

    setState(() {
      _isLoading = false;
      _step = 3;
    });
  }

  Future<void> _resetPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    _foundUser!.passwordHash = PasswordHelper.hashPassword(
      _newPasswordController.text,
    );
    await _foundUser!.save();

    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Password reset successfully!"),
          backgroundColor: _brandAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      Navigator.of(context).pop();
    }
  }

  // ignore: unused_element
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
    TextInputAction textInputAction = TextInputAction.done,
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
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _errorColor, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _errorColor, width: 1.5),
          ),
          errorStyle: const TextStyle(color: _errorColor, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final stepNum = index + 1;
        final isActive = _step == stepNum;
        final isDone = _step > stepNum;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDone || isActive ? _brandAccent : _fieldFill,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (stepNum < 3) const SizedBox(width: 6),
            ],
          ),
        );
      }),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case 1:
        return "Find your account";
      case 2:
        return "Verify your identity";
      case 3:
        return "Set new password";
      default:
        return "";
    }
  }

  String get _stepSubtitle {
    switch (_step) {
      case 1:
        return "Enter the email linked to your account";
      case 2:
        return "Answer your security question to continue";
      case 3:
        return "Choose a strong password you haven't used before";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _fieldFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _brandDeep,
              size: 18,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              _buildStepIndicator(),
              const SizedBox(height: 24),

              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _brandAccent.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_reset_rounded,
                    color: _brandAccent,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                _stepTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _brandDeep,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _stepSubtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: _labelColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              if (_step == 1)
                Form(
                  key: _emailFormKey,
                  child: Column(
                    children: [
                      _buildField(
                        controller: _emailController,
                        label: "Email Address",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: 8),
                      _buildButton(label: "Find Account", onTap: _findAccount),
                    ],
                  ),
                ),

              if (_step == 2)
                Form(
                  key: _answerFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _fieldFill,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              color: _labelColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _emailController.text.trim(),
                              style: const TextStyle(
                                color: _brandDeep,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
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
                              controller: _answerController,
                              textInputAction: TextInputAction.done,
                              style: const TextStyle(
                                color: _brandDeep,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? "Please enter your answer"
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
                                  borderSide: BorderSide.none,
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

                      _buildButton(
                        label: "Verify Answer",
                        onTap: _verifyAnswer,
                      ),
                    ],
                  ),
                ),

              if (_step == 3)
                Form(
                  key: _passwordFormKey,
                  child: Column(
                    children: [
                      _buildField(
                        controller: _newPasswordController,
                        label: "New Password",
                        icon: Icons.lock_outline_rounded,
                        obscure: true,
                        hasToggle: true,
                        isVisible: _showNewPassword,
                        onToggle: () => setState(
                          () => _showNewPassword = !_showNewPassword,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: Validators.validatePassword,
                      ),
                      _buildField(
                        controller: _confirmPasswordController,
                        label: "Confirm New Password",
                        icon: Icons.lock_outline_rounded,
                        obscure: true,
                        hasToggle: true,
                        isVisible: _showConfirmPassword,
                        onToggle: () => setState(
                          () => _showConfirmPassword = !_showConfirmPassword,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "Please confirm your password";
                          }
                          if (v != _newPasswordController.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                      ),
                      _buildButton(
                        label: "Reset Password",
                        onTap: _resetPassword,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
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
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}

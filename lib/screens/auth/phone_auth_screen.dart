import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../shop/home_screen.dart';

const _bgColor = Color(0xFFFFF8F3);
const _brandAccent = Colors.blue;
const _brandDeep = Color(0xFF1A1A2E);
const _fieldFill = Color(0xFFF5F5F8);
const _labelColor = Color(0xFF8B8FA8);
const _errorColor = Color(0xFFE53935);

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});
 
  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a valid phone number'),
        backgroundColor: _errorColor,
      ));
      return;
    }
    setState(() => _isLoading = true);
    final number = phone.startsWith('+') ? phone : '+91$phone';
    final error = await context.read<AuthProvider>().sendOtp(number);

await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    final otpError = context.read<AuthProvider>().otpError;
    setState(() {
      _isLoading = false;
      if (error == null && otpError == null) _otpSent = true;
    });

    final displayError = error ?? otpError;
    if (displayError != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(displayError),
        backgroundColor: _errorColor,
        duration: const Duration(seconds: 5),
      ));
    }
  }
  Future<void> _verifyOtp() async {
    setState(() => _isLoading = true);
    final error = await context
        .read<AuthProvider>()
        .verifyOtp(_otpController.text.trim());
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: _errorColor,
      ));
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      labelStyle: const TextStyle(color: _labelColor, fontSize: 14),
      prefixIcon: Icon(icon, color: _labelColor, size: 20),
      filled: true,
      fillColor: _fieldFill,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: _brandDeep),
                ),
              ),
              const SizedBox(height: 40),
              const Text('Phone Login',
                  style: TextStyle( 
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _brandDeep)),
              const SizedBox(height: 8),
              Text(
                _otpSent
                    ? 'Enter the OTP sent to your phone'
                    : 'We\'ll send you a one-time password',
                style: const TextStyle(fontSize: 14, color: _labelColor),
              ),
              const SizedBox(height: 40),

              if (!_otpSent) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: _brandDeep, fontSize: 15),
                  decoration: _inputDecoration('Phone number', Icons.phone_outlined),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Send OTP',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(
                      color: _brandDeep,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8),
                  textAlign: TextAlign.center,
                  decoration: _inputDecoration('Enter OTP', Icons.lock_outline_rounded)
                      .copyWith(counterText: ''),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Verify OTP',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: _isLoading ? null : _sendOtp,
                    child: const Text('Resend OTP',
                        style: TextStyle(
                            color: _brandAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
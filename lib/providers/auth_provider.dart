import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../utils/password_helper.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Phone OTP state
String? _verificationId;
  String? get verificationId => _verificationId;
  String? _otpError;
  String? get otpError => _otpError;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> loadCurrentUser() async {
    final email = Hive.box('settings').get('currentUser', defaultValue: '');
    if (email.isEmpty) return;
    final matches =
        Hive.box<User>('users').values.where((u) => u.email == email);
    if (matches.isNotEmpty) {
      _currentUser = matches.first;
      notifyListeners();
    }
  }

  // ── Email/Password Login ─────────────────────────────────────────
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      await _saveUserLocally(email.trim().toLowerCase());
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return _firebaseError(e.code);
    }
  }

  // ── Email/Password Signup ────────────────────────────────────────
  Future<String?> signup({
    required String name,
    required String email,
    required String password,
    required String securityAnswer,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      await credential.user?.updateDisplayName(name.trim());

      // also save to Hive for offline use
      final usersBox = Hive.box<User>('users');
      final exists = usersBox.values
          .any((u) => u.email == email.trim().toLowerCase());
      if (!exists) {
        await usersBox.add(User(
          name: name.trim(),
          email: email.trim().toLowerCase(),
          passwordHash: PasswordHelper.hashPassword(password),
          phone: '',
          securityAnswer: securityAnswer.trim().toLowerCase(),
        ));
      }
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return _firebaseError(e.code);
    }
  }

  // ── Google Sign-In ───────────────────────────────────────────────
  Future<String?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return 'Google sign-in cancelled';

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) return 'Google sign-in failed';

      // Save to Hive if new user
      final usersBox = Hive.box<User>('users');
      final email = user.email ?? '';
      final exists = usersBox.values.any((u) => u.email == email);
      if (!exists) {
        await usersBox.add(User(
          name: user.displayName ?? 'User',
          email: email,
          passwordHash: '',
          phone: user.phoneNumber ?? '',
          securityAnswer: '',
        ));
      }
      await _saveUserLocally(email);
      return null;
    } catch (e) {
      return 'Google sign-in failed: $e';
    }
  }

  // ── Phone — Send OTP ─────────────────────────────────────────────
Future<String?> sendOtp(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (fb.PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          await _saveUserLocally(
              _auth.currentUser?.email ?? _auth.currentUser?.phoneNumber ?? '');
          notifyListeners();
        },
        verificationFailed: (fb.FirebaseAuthException e) {
          debugPrint('OTP ERROR CODE: ${e.code}');
          debugPrint('OTP ERROR MSG: ${e.message}');
          _otpError = e.message ?? e.code;
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('OTP SENT — verificationId: $verificationId');
          _verificationId = verificationId;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
      return null;
    } catch (e) {
      debugPrint('SEND OTP EXCEPTION: $e');
      return 'Failed to send OTP: $e';
    }
  }
  // ── Phone — Verify OTP ───────────────────────────────────────────
  Future<String?> verifyOtp(String otp) async {
    if (_verificationId == null) return 'Please request OTP first';
    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) return 'Verification failed';

      final usersBox = Hive.box<User>('users');
      final phone = user.phoneNumber ?? '';
      final exists = usersBox.values.any((u) => u.phone == phone);
      if (!exists) {
        await usersBox.add(User(
          name: 'User',
          email: user.email ?? '',
          passwordHash: '',
          phone: phone,
          securityAnswer: '',
        ));
      }
      await _saveUserLocally(user.email ?? phone);
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return _firebaseError(e.code);
    }
  }

  // ── Logout ───────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await Hive.box('settings').delete('currentUser');
    _currentUser = null;
    notifyListeners();
  }

  void refreshUser() {
    final email = Hive.box('settings').get('currentUser', defaultValue: '');
    if (email.isEmpty) return;
    final matches =
        Hive.box<User>('users').values.where((u) => u.email == email);
    if (matches.isNotEmpty) {
      _currentUser = matches.first;
      notifyListeners();
    }
  }

  Future<void> _saveUserLocally(String email) async {
    await Hive.box('settings').put('currentUser', email);
    final matches =
        Hive.box<User>('users').values.where((u) => u.email == email);
    if (matches.isNotEmpty) {
      _currentUser = matches.first;
      notifyListeners();
    }
  }

  String _firebaseError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid email or password';
      case 'email-already-in-use':
        return 'Email already registered';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-verification-code':
        return 'Invalid OTP';
      case 'too-many-requests':
        return 'Too many attempts. Try later';
      default:
        return 'Something went wrong. Try again';
    }
  }
}
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/order.dart';
import '../utils/password_helper.dart';

class ProfileProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;
  String get userName => _user?.name ?? '';
  String get userEmail => _user?.email ?? '';
  String get userPhone => _user?.phone ?? '';

  int get totalOrders => _user == null
      ? 0
      : Hive.box<Order>('orders')
          .values
          .where((o) => o.userEmail == _user!.email)
          .length;

  double get totalSpent => _user == null
      ? 0
      : Hive.box<Order>('orders')
          .values
          .where((o) => o.userEmail == _user!.email)
          .fold(0, (sum, o) => sum + o.total);

  void loadUser() {
    final email = Hive.box('settings').get('currentUser', defaultValue: '');
    if (email.isEmpty) return;
    final matches =
        Hive.box<User>('users').values.where((u) => u.email == email);
    if (matches.isNotEmpty) {
      _user = matches.first;
      notifyListeners();
    }
  }

  Future<void> updateProfile(String name, String phone) async {
    if (_user == null) return;
    _user!.name = name.trim();
    _user!.phone = phone.trim();
    await _user!.save();
    notifyListeners();
  }

  Future<String?> changePassword(
      String currentPassword, String newPassword) async {
    if (_user == null) return 'User not found';

    if (PasswordHelper.hashPassword(currentPassword) != _user!.passwordHash) {
      return 'Current password is incorrect';
    }

    _user!.passwordHash = PasswordHelper.hashPassword(newPassword);
    await _user!.save();
    notifyListeners();
    return null; // null means success
  }

  void clear() {
    _user = null;
    notifyListeners();
  }
}
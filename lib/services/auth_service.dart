 import 'package:hive/hive.dart';

import '../models/user.dart';
import '../utils/password_helper.dart';

class AuthService {
  final Box<User> userBox = Hive.box<User>('users');

  final Box settings = Hive.box('settings');

  bool signup(User user) {
    bool exists = userBox.values.any(
      (u) => u.email == user.email,
    );

    if (exists) {
      return false;
    }

    user.passwordHash =
        PasswordHelper.hashPassword(user.passwordHash);

    userBox.add(user);

    return true;
  }

  bool login(
    String email,
    String password,
  ) {
    final hashed =
        PasswordHelper.hashPassword(password);

    try {
      final user = userBox.values.firstWhere(
        (u) =>
            u.email == email &&
            u.passwordHash == hashed,
      );

      settings.put(
        "currentUser",
        user.email,
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    settings.delete("currentUser");
  }

  bool isLoggedIn() {
    return settings.get("currentUser") != null;
  }

  String? currentUserEmail() {
    return settings.get("currentUser");
  }
}
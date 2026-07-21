import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 1)
class User extends HiveObject {

  @HiveField(0)
  String name;

  @HiveField(1)
  String email;

  @HiveField(2)
  String passwordHash;

  @HiveField(3)
  String phone;

  @HiveField(4)
  String? photoPath;

  @HiveField(5)
  String securityAnswer;

  User({
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.phone,
    this.photoPath,
    required this.securityAnswer,
  });

}
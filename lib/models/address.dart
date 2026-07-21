import 'package:hive/hive.dart';

part 'address.g.dart';

@HiveType(typeId: 4)
class Address extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String label;

  @HiveField(2)
  String fullName;

  @HiveField(3)
  String phone;

  @HiveField(4)
  String line1;

  @HiveField(5)
  String city;

  @HiveField(6)
  String pincode;

  @HiveField(7)
  String userEmail;

  @HiveField(8)
  bool isDefault;

  Address({
    required this.id,
    this.label = 'Home',
    required this.fullName,
    required this.phone,
    required this.line1,
    required this.city,
    required this.pincode,
    required this.userEmail,
    this.isDefault = false,
  });
}
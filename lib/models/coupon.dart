import 'package:hive/hive.dart';

part 'coupon.g.dart';

@HiveType(typeId: 6)
class Coupon extends HiveObject {
  @HiveField(0)
  String code;

  @HiveField(1)
  String type; // 'percent' or 'flat'

  @HiveField(2)
  double value;

  Coupon({
    required this.code,
    required this.type,
    required this.value,
  });
}
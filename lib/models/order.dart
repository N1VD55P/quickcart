import 'package:hive/hive.dart';

import 'cart_item.dart';

part 'order.g.dart';

@HiveType(typeId: 3)
class Order extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userEmail;

  @HiveField(2)
  List<CartItem> items;

  @HiveField(3)
  double total;

  @HiveField(4)
  DateTime dateTime;

  @HiveField(5)
  String status;

  @HiveField(6)
  String addressId;

  Order({
    required this.id,
    required this.userEmail,
    required this.items,
    required this.total,
    required this.dateTime, 
    required this.status,
    required this.addressId,
  });
}
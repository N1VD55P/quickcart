import 'package:hive/hive.dart';

part 'cart_item.g.dart';

@HiveType(typeId: 2)
class CartItem extends HiveObject {
  @HiveField(0)
  String productId;

  @HiveField(1)
  String name;

  @HiveField(2)
  double price;

  @HiveField(3)
  String imageUrl;

  @HiveField(4)
  int quantity;
  @HiveField(5)
  String category;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    required this.category,
  });
}

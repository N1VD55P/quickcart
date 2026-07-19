import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double price;

  @HiveField(3)
  String imageUrl;

  @HiveField(4)
  String description;

  @HiveField(5)
  String category;

  @HiveField(6)
  int stock;

  @HiveField(7)
  double originalPrice;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.originalPrice,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.stock,
  });

}
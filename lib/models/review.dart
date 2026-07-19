import 'package:hive/hive.dart';

part 'review.g.dart';

@HiveType(typeId: 5)
class Review extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String productId;

  @HiveField(2)
  String userEmail;

  @HiveField(3)
  int rating;

  @HiveField(4)
  String comment;

  @HiveField(5)
  DateTime dateTime;

  Review({
    required this.id,
    required this.productId,
    required this.userEmail,
    required this.rating,
    required this.comment,
    required this.dateTime,
  });
}
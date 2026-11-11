import 'package:hive_ce/hive.dart';

part 'post_hive_model.g.dart';

@HiveType(typeId: 0)
class PostHiveModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int userId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String body;

  PostHiveModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });
}

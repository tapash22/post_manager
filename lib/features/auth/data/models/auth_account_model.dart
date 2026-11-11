import 'package:hive_ce/hive.dart';

part 'auth_account_model.g.dart';

@HiveType(typeId: 1)
class AuthAccountModel extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String salt;

  @HiveField(2)
  final String passwordHash;

  AuthAccountModel({
    required this.name,
    required this.salt,
    required this.passwordHash,
  });
}

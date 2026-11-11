import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../features/auth/data/models/auth_account_model.dart';
import '../../features/posts/data/models/post_hive_model.dart';
import '../../hive_registrar.g.dart';

abstract final class AppDatabase {
  static const schemaVersion = 1;
  static const postsBoxName = 'posts';
  static const accountsBoxName = 'accounts';
  static const metadataBoxName = 'metadata';
  static bool _hiveInitialized = false;

  static Future<void> initialize({String? directory}) async {
    if (!_hiveInitialized) {
      if (directory == null) {
        await Hive.initFlutter();
      } else {
        Hive.init(directory);
      }
      _hiveInitialized = true;
      if (!Hive.isAdapterRegistered(0) && !Hive.isAdapterRegistered(1)) {
        Hive.registerAdapters();
      } else {
        if (!Hive.isAdapterRegistered(0)) {
          Hive.registerAdapter(PostHiveModelAdapter());
        }
        if (!Hive.isAdapterRegistered(1)) {
          Hive.registerAdapter(AuthAccountModelAdapter());
        }
      }
    }

    if (!Hive.isBoxOpen(postsBoxName)) {
      await Hive.openBox<PostHiveModel>(postsBoxName);
    }
    if (!Hive.isBoxOpen(accountsBoxName)) {
      await Hive.openBox<AuthAccountModel>(accountsBoxName);
    }
    final metadata = Hive.isBoxOpen(metadataBoxName)
        ? Hive.box<int>(metadataBoxName)
        : await Hive.openBox<int>(metadataBoxName);
    await _migrate(metadata);
  }

  static Box<PostHiveModel> get posts => Hive.box<PostHiveModel>(postsBoxName);

  static Box<AuthAccountModel> get accounts =>
      Hive.box<AuthAccountModel>(accountsBoxName);

  static Future<void> _migrate(Box<int> metadata) async {
    final storedVersion = metadata.get('schemaVersion') ?? 0;
    if (storedVersion > schemaVersion) {
      throw StateError(
        'Database version $storedVersion is newer than supported version $schemaVersion.',
      );
    }

    if (storedVersion < 1) {
      await metadata.put('schemaVersion', schemaVersion);
    }
  }
}

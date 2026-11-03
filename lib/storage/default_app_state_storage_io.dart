import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'app_state_storage.dart';

AppStateStorage createDefaultAppStateStorage() => SqliteAppStateStorage();

class SqliteAppStateStorage implements AppStateStorage {
  Future<Database>? _databaseFuture;
  Future<void>? _legacyMigration;

  Future<Database> get _database {
    return _databaseFuture ??= _openDatabase();
  }

  Future<Database> _openDatabase() async {
    final directory = await getDatabasesPath();
    final database = await openDatabase(
      path.join(directory, 'hsgx_local.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE app_state (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
    );
    _legacyMigration ??= _migrateSharedPreferences(database);
    await _legacyMigration;
    return database;
  }

  Future<void> _migrateSharedPreferences(Database database) async {
    final preferences = await SharedPreferences.getInstance();
    final legacyKeys = preferences
        .getKeys()
        .where((key) => key.startsWith('hsgx_flutter_state_'))
        .toList();
    if (legacyKeys.isEmpty) return;

    final existing = await database.query('app_state', limit: 1);
    if (existing.isNotEmpty) return;

    await database.transaction((transaction) async {
      for (final key in legacyKeys) {
        final value = preferences.getString(key);
        if (value == null) continue;
        await transaction.insert('app_state', {
          'key': key,
          'value': value,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });

    for (final key in legacyKeys) {
      await preferences.remove(key);
    }
  }

  @override
  Future<String?> read(String key) async {
    final database = await _database;
    final rows = await database.query(
      'app_state',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  @override
  Future<bool> write(String key, String value) async {
    try {
      final database = await _database;
      await database.transaction((transaction) async {
        await transaction.insert('app_state', {
          'key': key,
          'value': value,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      });
      return true;
    } on Object {
      return false;
    }
  }
}

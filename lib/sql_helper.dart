import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLHelper {
  static Future<Database> db() async {
    return openDatabase(
      join(await getDatabasesPath(), 'diary.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE diaries(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            feeling TEXT,
            description TEXT
          )
        ''');
      },
      version: 1,
    );
  }

  static Future<int> createDiary(String feeling, String desc) async {
    final dbClient = await db();
    return dbClient.insert('diaries', {
      'feeling': feeling,
      'description': desc,
    });
  }

  static Future<List<Map<String, dynamic>>> getDiaries() async {
    final dbClient = await db();
    return dbClient.query('diaries', orderBy: 'id DESC');
  }

  static Future<int> updateDiary(int id, String feeling, String desc) async {
    final dbClient = await db();
    return dbClient.update('diaries', {
      'feeling': feeling,
      'description': desc,
    }, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteDiary(int id) async {
    final dbClient = await db();
    await dbClient.delete('diaries', where: 'id = ?', whereArgs: [id]);
  }
}

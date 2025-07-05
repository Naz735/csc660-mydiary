import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLHelper {
  static Future<Database> _db() async {
    return openDatabase(
      join(await getDatabasesPath(), 'diary.db'),
      version: 2,
      onCreate: (db, v) async => db.execute('''
        CREATE TABLE diaries(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          feeling TEXT,
          description TEXT,
          date TEXT)
      '''),
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) await db.execute('ALTER TABLE diaries ADD COLUMN date TEXT');
      },
    );
  }

  /* 23(sql_helper.dart → createDiary()) for adding a new diary row */
  static Future<int> createDiary(String feeling, String desc) async {
    final db = await _db();
    return db.insert('diaries', {
      'feeling'    : feeling,
      'description': desc,
      /* 24(sql_helper.dart → date field) for storing current timestamp */
      'date'       : DateTime.now().toString().substring(0, 16),
    });
  }

  static Future<List<Map<String, dynamic>>> getDiaries() async {
    final db = await _db();
    return db.query('diaries', orderBy: 'id DESC');
  }

  static Future<int> updateDiary(int id, String feeling, String desc) async {
    final db = await _db();
    return db.update(
      'diaries',
      {
        'feeling'    : feeling,
        'description': desc,
        'date'       : DateTime.now().toString().substring(0, 16),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteDiary(int id) async {
    final db = await _db();
    await db.delete('diaries', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearAll() async {
    final db = await _db();
    await db.delete('diaries');
  }
}

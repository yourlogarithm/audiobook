import 'package:audiobook/classes/book.dart';
import 'package:audiobook/classes/settings.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';

class DatabaseProvider {
  DatabaseProvider._();
  static Database? _database;
  static Future<Database> get getDatabase async {
    if (_database != null) {
      return _database!;
    }

    _database = await createDatabase();

    return _database!;
  }

  static Future<Database> createDatabase() async {
    String dbPath = await getDatabasesPath();

    return await openDatabase(
        '$dbPath/audiobook.db',
        version: 4,
        onCreate: (Database db, int version) async {
          await db.execute(
              'CREATE TABLE bookProviders('
                  'id INTEGER PRIMARY KEY, '
                  'parentPath TEXT, '
                  'title TEXT, '
                  'author TEXT, '
                  'cover TEXT, '
                  'status STRING, '
                  'isBundle INTEGER, '
                  'elements BLOB, '
                  'bookIndex INTEGER, '
                  'bookmarks BLOB'
              ')'
          );
        }
    );
  }

  static Future<List<BookProvider>> get getBookProviders async {
    Database db = await getDatabase;
    List<Map<String, dynamic>> maps = await db.query('bookProviders');
    _check() async {
      List<Map<String, dynamic>> ready = [];
      for (int i = 0; i < maps.length; i++){
        Map<String, dynamic> newMap = {};
        maps[i].forEach((key, value) {
          newMap[key] = value;
        });
        if (await File(newMap['parentPath']).exists() || await Directory(newMap['parentPath']).exists()){
          bool edited = false;
          if (maps[i]['cover'] == Settings.defaultCover){
            if (!await File(maps[i]['cover']).exists()){
              edited = true;
              newMap['cover'] = Settings.defaultCover;
              await db.update(
                  'bookProviders',
                  newMap,
                  where: 'id = ?',
                  whereArgs: [newMap['id']]
              );
            }
          }
          if (!edited) {
            newMap['cover'] = maps[i]['cover'];
          }
          ready.add(newMap);
        } else {
          await db.delete(
              'bookProviders',
              where: 'id = ?',
              whereArgs: [newMap['id']]
          );
        }
      }
      return ready;
    }
    List<Map<String, dynamic>> edited = await _check();
    return List.generate(edited.length, (index) {
      return BookProvider.fromMap(edited[index]);
    });
  }

}
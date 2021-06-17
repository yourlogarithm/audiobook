import 'package:audiobook/classes/book.dart';
import 'package:audiobook/classes/bookmark.dart';
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
        version: 3,
        onCreate: (Database db, int version) async {
          await db.execute(
              'CREATE TABLE books('
                  'id INTEGER PRIMARY KEY, '
                  'title TEXT, author TEXT, '
                  'path TEXT, length INTEGER, '
                  'defaultCover INTEGER, cover TEXT, '
                  'checkpoint INTEGER'
                  ')'
          );
          await db.execute(
              'CREATE TABLE bookmarks('
                  'id INTEGER PRIMARY KEY, '
                  'bookTitle TEXT, '
                  'title TEXT, '
                  'time INTEGER'
                  ')'
          );
        }
    );
  }

  static Future<List<Book>> getBooks() async {
    Database db = await getDatabase;
    List<Map<String, dynamic>> maps = await db.query('books');
    _checkImage() async {
      List<Map<String, dynamic>> ready = [];
      for (int i = 0; i < maps.length; i++){
        Map<String, dynamic> newMap = {};
        newMap['id'] = maps[i]['id'];
        newMap['title'] = maps[i]['title'];
        newMap['author'] = maps[i]['author'];
        newMap['path'] = maps[i]['path'];
        newMap['length'] = maps[i]['length'];
        newMap['checkpoint'] = maps[i]['checkpoint'];
        if (await File(newMap['path']).exists()){
          bool edited = false;
          if (maps[i]['defaultCover'] == 0){
            if (!await File(maps[i]['cover']).exists()){
              edited = true;
              newMap['defaultCover'] = 1;
              newMap['cover'] = 'images/defaultcover.png';
              await db.update(
                  'books',
                  newMap,
                  where: 'id = ?',
                  whereArgs: [newMap['id']]
              );
            }
          }
          if (!edited) {
            newMap['defaultCover'] = maps[i]['defaultCover'];
            newMap['cover'] = maps[i]['cover'];
          }
          ready.add(newMap);
        } else {
          await db.delete(
              'books',
              where: 'id = ?',
              whereArgs: [newMap['id']]
          );
        }
      }
      return ready;
    }
    List<Map<String, dynamic>> edited = await _checkImage();
    return List.generate(edited.length, (index) {
      return Book.fromMap(edited[index]);
    });
  }

  static Future<List<Bookmark>> getBookmarks(String bookTitle) async {
    Database db = await getDatabase;
    List<Map<String, dynamic>> maps = await db.query(
        'bookmarks',
        where: 'bookTitle = ?',
        whereArgs: [bookTitle]
    );
    return List.generate(maps.length, (index) => Bookmark.fromMap(maps[index]));
  }
}
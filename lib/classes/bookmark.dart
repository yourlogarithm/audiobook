import 'package:sqflite/sqflite.dart';
import 'package:audiobook/classes/database.dart';

List<Bookmark> bookmarks = [];

class Bookmark {
  int? id;
  late String bookTitle;
  late String title;
  late Duration time;
  Bookmark({required this.bookTitle, required this.title, required this.time});
  Bookmark.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    bookTitle = map['bookTitle'];
    title = map['title'];
    time = Duration(seconds: map['time']);
  }
  Map<String, dynamic> toMap() {
    return {'bookTitle': bookTitle, 'title': title, 'time': time.inSeconds};
  }

  Future<void> insert() async {
    Database db = await DatabaseProvider.getDatabase;
    await db.insert('bookmarks', this.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update() async {
    Database db = await DatabaseProvider.getDatabase;
    await db.update('bookmarks', this.toMap(),
        where: 'id = ?', whereArgs: [this.id]);
  }

  Future<List<Bookmark>> remove() async {
    Database db = await DatabaseProvider.getDatabase;
    await db.delete('bookmarks', where: 'id = ?', whereArgs: [this.id]);
    List<Map<String, dynamic>> maps = await db.query(
        'bookmarks',
        where: 'bookTitle = ?',
        whereArgs: [bookTitle]
    );
    return List.generate(maps.length, (index) => Bookmark.fromMap(maps[index]));
  }
}

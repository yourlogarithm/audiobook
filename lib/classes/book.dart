import 'dart:io';
import 'package:audiobook/classes/database.dart';
import 'package:audiobook/classes/settings.dart';
import 'package:audiobook/pages/HomePage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

List<Book> books = [];

class Book {
  int? id;
  late String title;
  late String author;
  late String path;
  late Duration length;
  late Duration checkpoint;
  late bool defaultCover;
  late String cover;
  late String status;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.path,
    required this.length,
    required this.checkpoint,
    required this.defaultCover,
    required this.cover,
    required this.status
  });

  Book.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    title = map['title'];
    author = map['author'];
    path = map['path'];
    length = Duration(seconds: map['length']);
    checkpoint = Duration(seconds: map['checkpoint']);
    defaultCover = map['defaultCover'] == 1 ? true : false;
    cover = map['cover'];
    status = map['status'];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'path': path,
      'length': length.inSeconds,
      'checkpoint': checkpoint.inSeconds,
      'defaultCover': defaultCover ? 1 : 0,
      'cover': cover,
      'status': status
    };
  }

  Future<List<dynamic>> checkImage(Map<String, dynamic> map) async {
    bool edited = false;
    bool? localDefaultCover;
    String? localCover;
    if (map['defaultCover'] == 0) {
      if (!await File(map['cover']).exists()) {
        localDefaultCover = true;
        localCover = 'images/defaultcover.png';
        edited = true;
      }
    }
    if (!edited) {
      localDefaultCover = map['defaultCover'];
      localCover = map['cover'];
    }
    return [localDefaultCover!, localCover!];
  }

  bool compareTo(Book book) {
    bool same = false;
    if (this.length == book.length && this.path == book.path) {
      same = true;
    }
    return same;
  }

  Future<void> setDefaultCover() async {
    defaultCover = true;
    cover = Settings.dir.path + '/' + 'defaultCover.png';
    this.update();
  }

  Future<void> changeCover(File file) async {
    Directory? extStorage = await getExternalStorageDirectory();
    if (extStorage != null) {
      file.copy(extStorage.path + '/' + basename(file.path));
      defaultCover = false;
      cover = file.path;
      homeLibraryEditNotifier.value = !homeLibraryEditNotifier.value;
      this.update();
    }
  }

  Future<void> insert() async {
    Database db = await DatabaseProvider.getDatabase;
    List<Book> _books = await DatabaseProvider.getBooks();
    bool same = false;
    _books.forEach((book) {
      if (book.compareTo(this)) {
        same = true;
      }
    });
    if (!same) {
      if (animatedLibraryList.currentState != null){
        animatedLibraryList.currentState!.insertItem(books.length);
      }
      books.add(this);
      homeLibraryEditNotifier.value = !homeLibraryEditNotifier.value;
      await db.insert('books', this.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> remove() async {
    Database db = await DatabaseProvider.getDatabase;
    books.remove(this);
    await db.delete('books', where: 'id = ?', whereArgs: [this.id]);
  }

  Future<void> update() async {
    Database db = await DatabaseProvider.getDatabase;
    await db.update('books', this.toMap(), where: 'id = ?', whereArgs: [this.id]);
  }
}

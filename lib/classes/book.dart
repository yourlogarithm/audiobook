import 'dart:convert';
import 'dart:io';
import 'package:audiobook/classes/database.dart';
import 'package:audiobook/classes/settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

ValueNotifier<bool> booksChanged = ValueNotifier(false);
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
  List<Chapter> chapters = [];
  late ValueNotifier<Duration> checkpointNotifier;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.path,
    required this.length,
    required this.checkpoint,
    required this.defaultCover,
    required this.cover,
    required this.status,
    required this.chapters
  }) {
    checkpointNotifier = ValueNotifier(checkpoint);
  }

  void updateCheckpoint(Duration duration) {
    checkpoint = duration;
    checkpointNotifier.value = duration;
  }

  Book.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    title = map['title'];
    author = map['author'];
    path = map['path'];
    length = Duration(seconds: map['length']);
    checkpoint = Duration(seconds: map['checkpoint']);
    checkpointNotifier = ValueNotifier(checkpoint);
    defaultCover = map['defaultCover'] == 1 ? true : false;
    cover = map['cover'];
    status = map['status'];
    String chaptersEncoded = map['chapters'];
    Map<String, dynamic> chaptersMap = jsonDecode(chaptersEncoded);
    print(chaptersMap);
    chaptersMap.forEach((index, chapter) {
      chapters.add(Chapter.fromMap(chapter));
    });
  }

  Map<String, dynamic> toMap() {
    Map<String, Map<String, dynamic>> chaptersMap = {};
    for (int i = 0; i < chapters.length; i ++) {
      chaptersMap[i.toString()] = chapters[i].toMap();
    }
    return {
      'id': id,
      'title': title,
      'author': author,
      'path': path,
      'length': length.inSeconds,
      'checkpoint': checkpoint.inSeconds,
      'defaultCover': defaultCover ? 1 : 0,
      'cover': cover,
      'status': status,
      'chapters': jsonEncode(chaptersMap)
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
      books.add(this);
      booksChanged.value = !booksChanged.value;
      await db.insert('books', this.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> remove() async {
    Database db = await DatabaseProvider.getDatabase;
    books.remove(this);
    booksChanged.value = !booksChanged.value;
    await db.delete('books', where: 'id = ?', whereArgs: [this.id]);
  }

  Future<void> update() async {
    Database db = await DatabaseProvider.getDatabase;
    booksChanged.value = !booksChanged.value;
    await db.update('books', this.toMap(), where: 'id = ?', whereArgs: [this.id]);
  }
}

class Chapter {
  late String title;
  late Duration start;
  late Duration end;
  Chapter({required this.title, required this.start, required this.end});
  Chapter.fromMap(Map<String, dynamic> map) {
    title = map['title'];
    start = Duration(seconds: map['start']);
    end = Duration(seconds: map['end']);
  }
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'start': start.inSeconds,
      'end': end.inSeconds
    };
  }
}

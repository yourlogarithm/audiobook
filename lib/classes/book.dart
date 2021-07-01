import 'dart:convert';
import 'package:audiobook/classes/database.dart';
import 'package:audiobook/classes/settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

List<BookProvider> allBooks = [];
ValueNotifier<bool> booksChanged = ValueNotifier(false);

class BookProvider {

  static get nullBookProvider => BookProvider(
      id: -1,
      parentPath: 'none',
      title: 'Start listening to an audiobook',
      author: 'none',
      elements: [
        Book(
          id: -1,
          title: 'none',
          author: 'none',
          bookmarks: [],
          chapters: [],
          checkpoint: Duration(seconds: 0),
          cover: Settings.defaultCover,
          length: Duration(seconds: 100),
          path: 'none',
        )
      ],
      bookIndex: 0,
      isBundle: false,
      status: 'new'
  );

  BookProvider({
    required int id,
    required String parentPath,
    required String title,
    required String author,
    required String status,
    required bool isBundle,
    required List<Book> elements,
    required int bookIndex
  }){
    _id = id;
    _parentPath = parentPath;
    _title = title;
    _author = author;
    _status = status;
    _isBundle = isBundle;
    _elements = elements;
    _bookIndex = bookIndex;
  }

  BookProvider.fromMap(Map<String, dynamic> map) {
    _id = map['id'];
    _parentPath = map['parentPath'];
    _title = map['title'];
    _author = map['author'];
    _cover = map['cover'];
    _status = map['status'];
    _isBundle = map['isBundle'] == 1 ? true : false;
    _elements = decodeElements(map['elements']);
    _bookIndex = map['bookIndex'];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentPath': _parentPath,
      'title': title,
      'author': author,
      'cover': cover,
      'status': status,
      'isBundle': isBundle ? 1 : 0,
      'elements': elementsEncoded,
      'bookIndex': bookIndex
    };
  }

  Map<String, dynamic> toAudioTaskMap() {
    Map<String, dynamic> map = toMap();
    map['isBundle'] = isBundle;
    map['elements'] = List.generate(elements.length, (index) => elements[index].toMap());
    return map;
  }

  late int _id;
  late String _parentPath;
  late String _title;
  late String _author;
  String? _cover;
  late String _status;
  late bool _isBundle;
  late List<Book> _elements;
  late int _bookIndex;

  int get id => _id;
  String get title => _title;
  String get author => _author;
  bool get hasCover => _cover != null;
  String get cover {
    if (_cover != null) {
      return _cover!;
    }
    return currentBook.cover;
  }
  String coverOf(int index) {
    return _elements[index].cover;
  }
  String get status => _status;
  bool get isBundle => _isBundle;
  List<Book> get elements => _elements;
  int get bookIndex => _bookIndex;

  Book get currentBook => _elements[_bookIndex];

  String get elementsEncoded {
    return encode(elements);
  }

  List<Book> decodeElements(String encoded) {
    return decode(encoded, Book);
  }

  void changeTitle(String newTitle) {
    _title = newTitle;
    update();
  }
  void changeAuthor(String newAuthor) {
    _author = newAuthor;
    update();
  }
  Future<void> changeCover(String path) async {
    _cover = path;
    await update();
  }
  void setDefaultCover() {
    _cover = Settings.dir.path + '/' + 'defaultCover.png';
    update();
  }
  void changeStatus(String newStatus) {
    _status = newStatus;
    update();
  }
  void changeIndex(int newBookIndex) {
    _bookIndex = newBookIndex;
    update();
  }

  bool compareTo(BookProvider bookProvider){
    bool same = false;
    if (title == bookProvider.title && isBundle == bookProvider.isBundle || _parentPath == bookProvider._parentPath) {
      print(_parentPath);
      same = true;
    }
    return same;
  }
  
  Future<void> insert(BuildContext context) async {
    bool same = false;
    for (int i = 0; i < allBooks.length; i++){
      if (allBooks[i].compareTo(this)){
        same = true;
        break;
      }
    }
    if (!same){
      allBooks.add(this);
      booksChanged.value = !booksChanged.value;
      DatabaseProvider.getDatabase.then((db) {
        db.insert('bookProviders', toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: Duration(seconds: 1),
          backgroundColor: Settings.colors[6],
          content: Text(
            'Book already exists',
            style: TextStyle(
                fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
          )
        )
      );
    }
  }
  
  Future<void> remove() async {
    allBooks.remove(this);
    booksChanged.value = !booksChanged.value;
    DatabaseProvider.getDatabase.then((db) {
      db.delete('bookProviders', where: 'id = ?', whereArgs: [id]);
    });
  }
  
  Future<void> update() async {
    booksChanged.value = !booksChanged.value;
    DatabaseProvider.getDatabase.then((db) {
      db.update('bookProviders', toMap(), where: 'id = ?', whereArgs: [id]);
    });
  }
  
}

class Book {

  Book({
    required int id,
    required String title,
    required String author,
    required String path,
    required Duration checkpoint,
    required Duration length,
    required String cover,
    required List<Bookmark> bookmarks,
    required List<Chapter> chapters
  }) {
    _id = id;
    _title = title;
    _author = author;
    _path = path;
    _checkpoint = ValueNotifier(checkpoint);
    _length = length;
    _cover = cover;
    _bookmarks = bookmarks;
    _chapters = chapters;
  }

  Book.fromMap(Map<String, dynamic> map) {
    _id = map['id'];
    _title = map['title'];
    _author = map['author'];
    _path = map['path'];
    _checkpoint = ValueNotifier(Duration(seconds: map['checkpoint']));
    _length = Duration(seconds: map['length']);
    _cover = map['cover'];
    _bookmarks = decodeBookmarks(map['bookmarks']);
    _chapters = decodeChapters(map['chapters']);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'title': title,
      'author': author,
      'path': path,
      'checkpoint': checkpoint.value.inSeconds,
      'length': length.inSeconds,
      'cover': cover,
      'bookmarks': bookmarksEncoded,
      'chapters': chaptersEncoded
    };
  }

  late int _id;
  late String _title;
  late String _author;
  late String _path;
  late ValueNotifier<Duration> _checkpoint;
  late Duration _length;
  late String _cover;
  late List<Bookmark> _bookmarks;
  late List<Chapter> _chapters;

  int get id => _id;
  String get title => _title;
  String get author => _author;
  String get path => _path;
  ValueNotifier<Duration> get checkpoint => _checkpoint;
  Duration get length => _length;
  String get cover => _cover;
  List<Bookmark> get bookmarks => _bookmarks;
  List<Chapter> get chapters => _chapters;
  dynamic get currentChapter {
    try {
      return chapters.firstWhere((element) => element.start <= checkpoint.value && element.end >= checkpoint.value);
    } catch (e) {
      return null;
    }
  }

  String get chaptersEncoded {
    return encode(chapters);
  }

  List<Chapter> decodeChapters(String encoded) {
    return decode(encoded, Chapter);
  }

  String get bookmarksEncoded {
    return encode(bookmarks);
  }

  List<Bookmark> decodeBookmarks(String encoded) {
    return decode(encoded, Bookmark);
  }
  void changeTitle(String newTitle) {
    _title = newTitle;
  }
  void changeAuthor(String newAuthor){
    _author = newAuthor;
  }
  void setCheckpoint(Duration arg) {
    _checkpoint.value = arg;
    allBooks.firstWhere((element) => element.id == id).update();
  }
  void addBookmark(Bookmark bookmark) {
    _bookmarks.add(bookmark);
    allBooks.firstWhere((element) => element.id == id).update();
  }
  void removeBookmark(Bookmark bookmark) {
    _bookmarks.remove(bookmark);
    allBooks.firstWhere((element) => element.id == id).update();
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

class Bookmark {
  late int _id;
  late String _title;
  late Duration _time;
  Bookmark({required int id, required String title, required Duration time}){
    _id = id;
    _title = title;
    _time = time;
  }
  Bookmark.fromMap(Map<String, dynamic> map) {
    _id = map['index'];
    _title = map['title'];
    _time = Duration(seconds: map['time']);
  }
  Map<String, dynamic> toMap() {
    return {'index': _id, 'title': _title, 'time': _time.inSeconds};
  }

  int get id => _id;
  String get title => _title;
  Duration get time => _time;

  void changeTitle(String newTitle) {
    _title = newTitle;
    allBooks.firstWhere((element) => element.id == id).update();
  }
}

String encode(dynamic element) {
  List<Map<String, dynamic>> maps = List.generate(element.length, (index) {
    return element[index].toMap();
  });
  return jsonEncode(maps);
}


dynamic decode(String encoded, Type type) {
  List<dynamic> maps = jsonDecode(encoded);
  switch (type) {
    case Book:
      return List.generate(maps.length, (index) {
        return Book.fromMap(maps[index]);
      });
    case Chapter:
      return List.generate(maps.length, (index) {
        return Chapter.fromMap(maps[index]);
      });
    case Bookmark:
      return List.generate(maps.length, (index) {
        return Bookmark.fromMap(maps[index]);
      });
  }
}


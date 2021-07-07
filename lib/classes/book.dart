import 'dart:convert';
import 'package:audiodept/classes/database.dart';
import 'package:audiodept/classes/settings.dart';
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
        chapters: [],
        checkpoint: Duration(seconds: 0),
        cover: Settings.defaultCover,
        length: Duration(seconds: 100),
        path: 'none',
      )
    ],
    bookIndex: 0,
    isBundle: false,
    status: 'new',
    bookmarks: []
  );

  BookProvider({
    required int id,
    required String parentPath,
    required String title,
    required String author,
    required String status,
    required bool isBundle,
    required List<Book> elements,
    required int bookIndex,
    required List<Bookmark> bookmarks
  }){
    _id = id;
    _parentPath = parentPath;
    _title = title;
    _author = author;
    _status = status;
    _isBundle = isBundle;
    _elements = elements;
    _bookIndex = ValueNotifier(bookIndex);
    _bookmarks = bookmarks;
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
    _bookIndex = ValueNotifier(map['bookIndex']);
    _bookmarks = decodeBookmarks(map['bookmarks']);
  }

  BookProvider.fromAudioTaskMap(Map<String, dynamic> map) {
    _id = map['id'];
    _parentPath = map['parentPath'];
    _title = map['title'];
    _author = map['author'];
    _cover = map['cover'];
    _status = map['status'];
    _isBundle = map['isBundle'];
    _elements = List.generate(map['elements'].length, (index) {
      Map<String, dynamic> bookMap = {};
      map['elements'][index].forEach((key, value) {
        bookMap[key] = value;
      });
      return Book.fromAudioTaskMap(bookMap);
    });
    _bookIndex = ValueNotifier(map['bookIndex']);
    _bookmarks = List.generate(map['bookmarks'].length, (index) => Bookmark.fromMap(map['bookmarks'][index]));
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentPath': parentPath,
      'title': title,
      'author': author,
      'cover': _cover != null ? cover : null,
      'status': status,
      'isBundle': isBundle ? 1 : 0,
      'elements': elementsEncoded,
      'bookIndex': bookIndex.value,
      'bookmarks': encode(bookmarks)
    };
  }

  Map<String, dynamic> toAudioTaskMap() {
    return {
      'id': id,
      'parentPath': parentPath,
      'title': title,
      'author': author,
      'cover': _cover != null ? cover : null,
      'status': status,
      'isBundle': isBundle,
      'bookIndex': bookIndex.value,
      'elements': List.generate(elements.length, (index) => elements[index].toAudioTaskMap()),
      'bookmarks': List.generate(bookmarks.length, (index) => bookmarks[index].toMap()),
    };
  }

  late int _id;
  late String _parentPath;
  late String _title;
  late String _author;
  String? _cover;
  late String _status;
  late bool _isBundle;
  late List<Book> _elements;
  late ValueNotifier<int> _bookIndex;
  late List<Bookmark> _bookmarks;

  int get id => _id;
  String get parentPath => _parentPath;
  String get title => _title;
  String get author => _author;
  // bool get hasCover => _cover != null;
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
  ValueNotifier<int> get bookIndex => _bookIndex;
  List<Bookmark> get bookmarks => _bookmarks;

  Book get currentBook => _elements[_bookIndex.value];

  String get elementsEncoded {
    return encode(elements);
  }

  List<Book> decodeElements(String encoded) {
    return decode(encoded, Book);
  }

  String get bookmarksEncoded {
    return encode(bookmarks);
  }

  List<Bookmark> decodeBookmarks(String encoded) {
    return decode(encoded, Bookmark);
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
    _bookIndex.value = newBookIndex;
    update();
  }

  bool compareTo(BookProvider bookProvider){
    bool same = false;
    if (title == bookProvider.title && isBundle == bookProvider.isBundle || _parentPath == bookProvider._parentPath) {
      same = true;
    }
    return same;
  }

  void addBookmark(Bookmark bookmark) {
    _bookmarks.add(bookmark);
    update();
  }
  void removeBookmark(Bookmark bookmark) {
    _bookmarks.remove(bookmark);
    update();
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
            'This book already exists',
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
    required List<Chapter> chapters
  }) {
    _id = id;
    _title = title;
    _author = author;
    _path = path;
    _checkpoint = ValueNotifier(checkpoint);
    _length = length;
    _cover = cover;
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
    _chapters = decodeChapters(map['chapters']);
  }

  Book.fromAudioTaskMap(Map<String, dynamic> map){
    _id = map['id'];
    _title = map['title'];
    _author = map['author'];
    _path = map['path'];
    _checkpoint = ValueNotifier(Duration(seconds: map['checkpoint']));
    _length = Duration(seconds: map['length']);
    _cover = map['cover'];
    _chapters = List.generate(map['chapters'].length, (index) {
      Map<String, dynamic> chapterMap = {};
      map['chapters'][index].forEach((key, value) {
        chapterMap[key] = value;
      });
      return Chapter.fromMap(chapterMap);
    });
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
      'chapters': chaptersEncoded
    };
  }

  Map<String, dynamic> toAudioTaskMap() {
    Map<String, dynamic> map = toMap();
    map['chapters'] = List.generate(chapters.length, (i) {
      return chapters[i].toMap();
    });
    return map;
  }

  late int _id;
  late String _title;
  late String _author;
  late String _path;
  late ValueNotifier<Duration> _checkpoint;
  late Duration _length;
  late String _cover;
  late List<Chapter> _chapters;

  int get id => _id;
  String get title => _title;
  String get author => _author;
  String get path => _path;
  ValueNotifier<Duration> get checkpoint => _checkpoint;
  Duration get length => _length;
  String get cover => _cover;
  List<Chapter> get chapters => _chapters;
  dynamic get currentChapter {
    try {
      return chapters.firstWhere((element) => element.start <= checkpoint.value && element.end >= checkpoint.value);
    } catch (e) {
      return null;
    }
  }
  dynamic get nextChapter {
    try {
      return chapters[chapters.indexOf(currentChapter)+1];
    } catch (e) {
      return null;
    }
  }
  dynamic get previousChapter {
    try {
      return chapters[chapters.indexOf(currentChapter)-1];
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
  late int _bookIndex;
  late String _title;
  late Duration _time;
  Bookmark({required int id, required int bookIndex, required String title, required Duration time}){
    _id = id;
    _bookIndex = bookIndex;
    _title = title;
    _time = time;
  }
  Bookmark.fromMap(Map<String, dynamic> map) {
    _id = map['id'];
    _bookIndex = map['bookIndex'];
    _title = map['title'];
    _time = Duration(seconds: map['time']);
  }
  Map<String, dynamic> toMap() {
    return {'id': _id, 'bookIndex': _bookIndex, 'title': _title, 'time': _time.inSeconds};
  }

  int get id => _id;
  String get title => _title;
  Duration get time => _time;
  int get bookIndex => _bookIndex;

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


import 'dart:typed_data';
import 'package:audiobook/classes/book.dart';
import 'package:audiobook/classes/explorer.dart';
import 'package:audiobook/classes/scrollBehavior.dart';
import 'package:audiobook/classes/settings.dart';
import 'package:audiobook/content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'dart:io';
import 'package:path/path.dart' as dpath;
import 'package:audiotagger/audiotagger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:auto_size_text/auto_size_text.dart';

class AddBookPage extends StatefulWidget {
  // const AddBookPage({Key key}) : super(key: key);

  @override
  _AddBookPageState createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage>
    with TickerProviderStateMixin {
  final List<String> audioFormats = [
    '.mp3',
    '.aax',
    '.m4a',
    '.m4b',
    '.aac',
    '.m4p',
    '.ogg',
    '.wma',
    '.flac',
    '.alac'
  ];

  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Settings.theme.value == 'Dark' ? Settings.colors[2] : Settings.colors[1],
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 25),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.1,
            child: SafeArea(
              child: TabBar(
                controller: _tabController,
                labelPadding: EdgeInsets.zero,
                labelColor: Settings.colors[3],
                labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 20),
                indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(color: Settings.colors[3], width: 4)
                ),
                tabs: [Text('Default'), Text('File system')],
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.9,
            child: Container(
              decoration: BoxDecoration(
                  color: Settings.colors[0],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  boxShadow: Settings.theme.value == 'Dark'
                      ? [
                          BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.1),
                              offset: Offset(0, -3),
                              blurRadius: 5,
                              spreadRadius: 1)
                        ]
                      : []),
              child: ScrollConfiguration(
                behavior: MyBehavior(),
                child: TabBarView(
                  controller: _tabController,
                  children: [WidgetExplorer(isDefault: true), WidgetExplorer()],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class WidgetExplorer extends StatefulWidget {
  final bool isDefault;
  WidgetExplorer({this.isDefault = false});
  @override
  _WidgetExplorerState createState() => _WidgetExplorerState();
}

class _WidgetExplorerState extends State<WidgetExplorer> {
  late FileExplorerAudio explorer;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    explorer = FileExplorerAudio(isDefault: widget.isDefault, context: context);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: explorer.path,
        builder: (BuildContext context, value, _) {
          return FutureBuilder(
              future: explorer.directories(),
              builder: (context, AsyncSnapshot<Widget> snapshot) {
                if (snapshot.hasData) {
                  return snapshot.data!;
                } else {
                  return Container();
                }
              });
        });
  }
}

class FileExplorerAudio extends FileExplorer {
  late bool isDefault;
  late BuildContext context;
  FileExplorerAudio({this.isDefault = false, required this.context}) {
    if (isDefault) {
      this.path.value = Settings.defaultFolder;
    }
  }

  Future<void> buildBookProvider(File file, {bool isBundle = false}) async {
    moveBlocked = true;
    if (!isBundle) {
      Book book = await selectFile(file);
      BookProvider bookProvider = BookProvider(
          id: allBooks.isNotEmpty ? allBooks.last.id + 1 : 1,
          parentPath: file.path,
          title: book.title,
          author: book.author,
          status: 'new',
          isBundle: false,
          elements: [book],
          bookIndex: 0
      );
      await bookProvider.insert(context).whenComplete(() => moveHome());
      moveBlocked = false;
    } else {
      List<FileSystemEntity> allFiles = await this.listDir(file.path);
      List<Book> books = [];
      for(int i = 0; i < allFiles.length; i++){
        if (FileExplorer.audioFormats.contains(dpath.extension(allFiles[i].path))){
          books.add(await selectFile(File(allFiles[i].path)));
        }
      }
      if (books.isNotEmpty) {
        bool sameAuthor = true;
        for (int i = 0; i < books.length-1; i++){
          if (books[i].author != books[i+1].author){
            sameAuthor = false;
          }
        }
        BookProvider bookProvider = BookProvider(
            id: allBooks.isNotEmpty ? allBooks.last.id + 1 : 1,
            parentPath: file.path,
            title: dpath.basename(file.path),
            author: sameAuthor ? books[0].author : 'Multiple authors',
            status: 'new',
            isBundle: true,
            elements: books,
            bookIndex: 0
        );
        await bookProvider.insert(context).whenComplete(() => moveHome());
        moveBlocked = false;
      }
    }
  }

  Future<Book> selectFile(File file) async {
    List<FileSystemEntity> parent = await this.listDir(file.parent.path);
    List<Chapter> chapters = [];
    List? chaptersData;
    int length = 1;
    Map data = {};
    final FlutterFFprobe _flutterFFprobe = FlutterFFprobe();
    await _flutterFFprobe.executeWithArguments(['-loglevel', 'error', '-hide_banner', '-i', file.path, '-show_chapters']);
    await _flutterFFprobe.getMediaInformation(file.path).then((value)  {
      data = value.getAllProperties();
      length = int.parse(data['format']['duration'].split('.')[0]);
      chaptersData = data['chapters'];
      if (chaptersData != null){
        if (chaptersData!.isNotEmpty) {
          chaptersData!.asMap().forEach((index, chapter) {
            String title = index.toString();
            if (chapter['tags'] != null){
              if (chapter['tags']['title'] != null){
                title = chapter['tags']['title'];
              }
            }
            Duration start = Duration(seconds: int.parse(chapter['start_time'].split('.')[0]));
            Duration end = Duration(seconds: int.parse(chapter['end_time'].split('.')[0]));
            chapters.add(Chapter(title: title, start: start, end: end));
          });
        }
      }
    });
    String? cover;
    Uint8List? artwork = await Audiotagger().readArtwork(path: file.path);
    if (artwork != null) {
      Directory? extStorage = await getExternalStorageDirectory();
      if (extStorage != null) {
        File imageFile = File(extStorage.path + '/' + dpath.basename(file.path));
        if (!await imageFile.exists()) {
          imageFile.create(recursive: true);
        }
        imageFile.writeAsBytes(artwork);
        cover = imageFile.path;
      }
    } else {
      parent.forEach((element) {
        if (FileExplorer.imageFormats.contains(dpath.extension(element.path))) {
          cover = element.path;
        }
      });
    }
    if (cover == null) {
      cover = Settings.defaultCover;
    }
    Book book = Book(
      id: allBooks.isNotEmpty ? allBooks.last.id + 1 : 1,
      title: dpath.basename(file.path),
      author: 'No author',
      path: file.path,
      length: Duration(seconds: length),
      cover: cover!,
      checkpoint: Duration(seconds: 0),
      bookmarks: [],
      chapters: chapters,
    );
    if (data['format']['tags'] != null) {
      if (data['format']['tags'].isNotEmpty) {
        if (data['format']['tags']['title'] != null) {
          if (data['format']['tags']['title'].isNotEmpty) {
            book.changeTitle(data['format']['tags']['title']);
          }
        }
      }
      if (data['format']['tags']['artist'] != null) {
        if (data['format']['tags']['artist'].isNotEmpty) {
          book.changeAuthor(data['format']['tags']['artist']);
        }
      }
    }
    moveBlocked = false;
    return book;
  }

  Future<Widget> directories() async {
    List<FileSystemEntity> dirs = await listDir(this.path.value);
    dirs.sort((a, b) => a.path.compareTo(b.path));
    if (!isDefault) {
      if (this.path.value != FileExplorer.rootPath) {
        dirs.insert(0, File(File(this.path.value).parent.path));
      }
    } else {
      if (this.path.value != FileExplorer.rootPath &&
          this.path.value != Settings.defaultFolder) {
        dirs.insert(0, File(File(this.path.value).parent.path));
      }
    }
    List<Widget> folders = [];
    dirs.forEach((directory) {
      String _path = directory.path;
      String _extension = dpath.extension(_path);
      if (FileExplorer.audioFormats.contains(_extension) || (_extension == '' && Directory(_path).existsSync())) {
        folders.add(Column(
          children: [
            Expanded(
                flex: 3,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return Container(
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                            color: Settings.theme.value == 'Dark'
                                ? Settings.colors[1]
                                : Settings.colors[6],
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: Settings.theme.value == 'Dark'
                                ? [
                                    BoxShadow(
                                        color: Color.fromRGBO(0, 0, 0, 0.1),
                                        spreadRadius: 1,
                                        blurRadius: 5)
                                  ]
                                : [
                                    BoxShadow(
                                        color:
                                            Settings.colors[6].withOpacity(0.3),
                                        spreadRadius: 0.1,
                                        blurRadius: 10)
                                  ]),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                              onTap: () => _extension == '' ? this.navigateToDir(_path) : buildBookProvider(File(_path)),
                              onLongPress: () async {
                                if (await Directory(_path).exists())
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                          backgroundColor: Settings.colors[0],
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(25)),
                                          actionsPadding:
                                              EdgeInsets.fromLTRB(0, 0, 20, 5),
                                          contentPadding: EdgeInsets.fromLTRB(
                                              24, 20, 24, 12),
                                          title: AutoSizeText(
                                            'Add the whole folder as an audio book?',
                                            style: TextStyle(
                                                color: Settings.colors[3],
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w600,
                                                fontSize: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.045),
                                          ),
                                          actions: [
                                            InkWell(
                                              onTap: () =>
                                                  Navigator.pop(context),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                child: Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                      color: Settings.colors[6],
                                                      fontFamily: 'Poppins',
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                buildBookProvider(File(_path),
                                                    isBundle: true);
                                                Navigator.pop(context);
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                child: Text(
                                                  'Confirm',
                                                  style: TextStyle(
                                                      color: Settings.colors[6],
                                                      fontFamily: 'Poppins',
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                            )
                                          ],
                                        ));
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: _extension == ''
                                  ? Icon(
                                      _path == File(this.path.value).parent.path
                                          ? Icons.subdirectory_arrow_left
                                          : Icons.folder,
                                      color: Settings.theme.value == 'Dark'
                                          ? Settings.colors[7]
                                          : Settings.colors[0],
                                      size: 40)
                                  : Center(
                                      child: AutoSizeText(
                                      _extension,
                                      maxLines: 1,
                                      style: TextStyle(
                                          fontFamily: 'Open Sans',
                                          fontWeight: FontWeight.bold,
                                          color: Settings.theme.value == 'Dark'
                                              ? Settings.colors[7]
                                              : Settings.colors[0]),
                                    ))),
                        ));
                  },
                )),
            Expanded(
              flex: 1,
              child: Center(
                  child: AutoSizeText(
                dpath.basename(_path) == '0'
                    ? 'Internal Storage'
                    : dpath.basename(_path),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                maxLines: 1,
                minFontSize: 12,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: Settings.colors[3],
                ),
              )),
            )
          ],
        ));
      }
    });
    return GridView.count(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      physics: BouncingScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 0.75,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      children: folders,
    );
  }
}


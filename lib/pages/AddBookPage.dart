import 'dart:typed_data';
import 'package:audiobook/classes/book.dart';
import 'package:audiobook/classes/explorer.dart';
import 'package:audiobook/classes/scrollBehavior.dart';
import 'package:audiobook/classes/settings.dart';
import 'package:audiobook/content.dart';
import 'package:audiotagger/models/audiofile.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_ffmpeg/media_information.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:audiotagger/audiotagger.dart';
import 'package:path_provider/path_provider.dart';

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
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 25),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.1,
          color: Settings.theme.value == 'Dark'
              ? Settings.colors[2]
              : Settings.colors[1],
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
          color: Settings.theme.value == 'Dark'
              ? Settings.colors[2]
              : Settings.colors[1],
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
    explorer = FileExplorerAudio(isDefault: widget.isDefault);
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

  FileExplorerAudio({this.isDefault = false}) {
    if (isDefault) {
      this.path.value = Settings.defaultFolder;
    }
  }

  void selectFile(File file) async {
    Audiotagger tagger = Audiotagger();
    Tag? tag = await tagger.readTags(path: file.path);
    AudioFile? audioFile = await tagger.readAudioFile(path: file.path);
    List<FileSystemEntity> parent = await this.listDir(file.parent.path);
    List<Chapter> chapters = [];
    List? chaptersData;
    final FlutterFFprobe _flutterFFprobe = FlutterFFprobe();
    await _flutterFFprobe.executeWithArguments(['-i', file.path, '-print_format', 'json', '-show_chapters']);
    await _flutterFFprobe.getMediaInformation(file.path).then((value)  {
      Map data = value.getAllProperties();
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
    bool defaultCover = true;
    String? cover;
    Uint8List? artwork = await tagger.readArtwork(path: file.path);
    if (artwork != null) {
      Directory? extStorage = await getExternalStorageDirectory();
      if (extStorage != null) {
        File imageFile = File(extStorage.path + '/' + basename(file.path));
        if (!await imageFile.exists()) {
          imageFile.create(recursive: true);
        }
        imageFile.writeAsBytes(artwork);
        defaultCover = false;
        cover = imageFile.path;
      }
    } else {
      parent.forEach((element) {
        if (FileExplorer.imageFormats.contains(extension(element.path))) {
          defaultCover = false;
          cover = element.path;
        }
      });
    }
    if (cover == null) {
      defaultCover = true;
      cover = Settings.dir.path + '/' + 'defaultCover.png';
    }
    Book book = Book(
      id: books.isEmpty ? 1 : books.last.id! + 1,
      title: 'title',
      author: 'author',
      path: file.path,
      length: Duration(seconds: audioFile!.length!),
      defaultCover: defaultCover,
      cover: cover!,
      checkpoint: ValueNotifier(Duration(seconds: 0)),
      status: 'new',
      chapters: chapters
    );
    bool titleEdited = false;
    bool authorEdited = false;
    if (tag != null) {
      if (tag.title != null) {
        if (tag.title!.isNotEmpty) {
          book.title = tag.title!;
          titleEdited = true;
        }
      }
      if (tag.artist != null) {
        if (tag.artist!.isNotEmpty) {
          book.author = tag.artist!;
          authorEdited = true;
        }
      }
    }
    if (!titleEdited) {
      book.title = basename(file.path);
    }
    if (!authorEdited) {
      book.author = 'No author';
    }
    await book.insert();
    moveHome();
  }

  Future<Widget> directories() async {
    List<FileSystemEntity> dirs = await this.listDir(this.path.value);
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
      String _extension = extension(_path);
      if (FileExplorer.audioFormats.contains(_extension) ||
          (_extension == '' && Directory(_path).existsSync())) {
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
                              onTap: () => _extension == ''
                                  ? this.navigateToDir(_path)
                                  : selectFile(File(_path)),
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
                                      child: Text(
                                      _extension,
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
                  child: Text(
                basename(_path) == '0' ? 'Internal Storage' : basename(_path),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Open Sans',
                    height: 1,
                    fontWeight: FontWeight.w600,
                    color: Settings.colors[3],
                    fontSize: 12),
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

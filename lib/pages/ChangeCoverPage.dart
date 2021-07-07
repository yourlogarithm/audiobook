import 'dart:io';
import 'package:audiodept/classes/book.dart';
import 'package:audiodept/classes/explorer.dart';
import 'package:audiodept/classes/settings.dart';
import 'package:audiodept/content.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

class ChangeCoverPage extends StatefulWidget {
  final BookProvider bookProvider;

  const ChangeCoverPage({required this.bookProvider});

  @override
  _ChangeCoverPageState createState() => _ChangeCoverPageState();
}

class _ChangeCoverPageState extends State<ChangeCoverPage> {

  late FileExplorerImage explorer;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    explorer = FileExplorerImage(widget.bookProvider);
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
              height: MediaQuery.of(context).size.height * 0.10,
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add image',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          color: Settings.colors[3]
                      ),
                    ),
                  ],
                ),
              )
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.9,
            child: Container(
                decoration: BoxDecoration(
                    color: Settings.colors[0],
                    borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                    boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.1), offset: Offset(0, -3), blurRadius: 5, spreadRadius: 1)]
                ),
                child: ValueListenableBuilder(
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
                          }
                      );
                    }
                )
            ),
          )
        ],
      ),
    );
  }
}

class FileExplorerImage extends FileExplorer {
  late BookProvider bookProvider;

  FileExplorerImage(BookProvider ab) {
    bookProvider = ab;
  }

  void selectFile(BookProvider bookProvider, File file) async {
    bookProvider.changeCover(file.path).whenComplete(() => moveHome());
  }

  Future<Widget> directories() async {
    List<FileSystemEntity> dirs = await this.listDir(this.path.value);
    dirs.sort((a, b) => a.path.compareTo(b.path));
    if (this.path.value != FileExplorer.rootPath) {
      dirs.insert(0, File(File(this.path.value).parent.path));
    }
    List<Widget> folders = [];
    dirs.forEach((directory) {
      String _path = directory.path;
      String _extension = extension(_path);
      if (FileExplorer.imageFormats.contains(_extension) ||
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
                                            Settings.colors[6].withOpacity(0.5),
                                        spreadRadius: 0.1,
                                        blurRadius: 10)
                                  ]),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                              onTap: () => _extension == ''
                                  ? this.navigateToDir(_path)
                                  : selectFile(bookProvider, File(_path)),
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
                                              : Settings.colors[0]
                    ),
                                    ))),
                        ));
                  },
                )),
            Expanded(
              flex: 1,
              child: Center(
                  child: AutoSizeText(
                basename(_path) == '0' ? 'Internal Storage' : basename(_path),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                maxLines: 1,
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

import 'dart:io';

import 'package:audiobook/classes/book.dart';
import 'package:audiobook/classes/explorer.dart';
import 'package:audiobook/classes/settings.dart';
import 'package:audiobook/content.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

class ChangeCoverPage extends StatefulWidget {
  final Book book;

  const ChangeCoverPage({required this.book});

  @override
  _ChangeCoverPageState createState() => _ChangeCoverPageState();
}

class _ChangeCoverPageState extends State<ChangeCoverPage> {

  late FileExplorerImage explorer;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    explorer = FileExplorerImage(widget.book);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
            padding: EdgeInsets.symmetric(horizontal: 25),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.10,
            color: Settings.colors[2],
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
                        color: Colors.white
                    ),
                  ),
                ],
              ),
            )
        ),
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.9,
          color: Settings.colors[2],
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
    );
  }
}

class FileExplorerImage extends FileExplorer {
  late Book book;

  FileExplorerImage(Book ab) {
    book = ab;
  }

  void selectFile(Book book, File file) async {
    book.changeCover(file).whenComplete(() => moveHome());
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
                                  : selectFile(book, File(_path)),
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

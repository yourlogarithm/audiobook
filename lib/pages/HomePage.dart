import 'dart:io';
import 'package:audiobook/classes/book.dart';
import 'package:audiobook/classes/bookFocusedMenu.dart';
import 'package:audiobook/classes/player.dart';
import 'package:audiobook/classes/scrollBehavior.dart';
import 'package:audiobook/classes/settings.dart';
import 'package:audiobook/content.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  // const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Settings.colors[1],
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.3,
                decoration: BoxDecoration(
                    color: Settings.colors[0],
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(30)),
                    boxShadow: Settings.theme.value == 'Dark'
                        ? [
                            BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.15),
                                spreadRadius: 1,
                                blurRadius: 10)
                          ]
                        : []
                ),
                child: SafeArea(
                  child: ValueListenableBuilder(
                    valueListenable: Settings.lastListenedBook,
                    builder: (context, value, _) {
                      BookProvider bookProvider = allBooks.firstWhere((bookProvider) => bookProvider.id == value, orElse: () => BookProvider.nullBookProvider);
                      return GestureDetector(
                        onTap: () {
                          Content.contentNavigatorKey.currentState!.pushReplacementNamed('/bookPage', arguments: bookProvider);
                        },
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.9,
                                height: MediaQuery.of(context).size.height * 0.15,
                                child: Row(
                                  children: [
                                    Expanded(
                                        flex: 1,
                                        child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.file(File(bookProvider.cover), fit: BoxFit.fill)
                                        )
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.05),
                                        child: AutoSizeText(
                                          bookProvider.title,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 4,
                                          minFontSize: MediaQuery.of(context).size.height >= 720 ? 18 : 14,
                                          style: TextStyle(
                                              color: Settings.colors[3],
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600,
                                              // fontSize: 18
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              AudioProgressBar(bookProvider: bookProvider)
                            ],
                          ),
                      );
                      }
                  ),
                ),
              ),
              Library()
            ],
          ),
          Positioned(
              bottom: MediaQuery.of(context).size.height * 0.08,
              right: MediaQuery.of(context).size.width * 0.05,
              child: Container(
                decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                  BoxShadow(
                      color: Settings.colors[6].withOpacity(0.5),
                      spreadRadius: 0.3,
                      blurRadius: 7)
                ]),
                child: FloatingActionButton(
                  heroTag: null,
                  onPressed: () {
                    Content.contentNavigatorKey.currentState!.pushReplacementNamed('/addBook');
                  },
                  elevation: 0,
                  backgroundColor: Settings.colors[6],
                  child: Icon(Icons.add, color: Colors.white),
                ),
              )
          )
        ],
      ),
    );
  }
}

class Library extends StatefulWidget {
  @override
  LibraryState createState() => LibraryState();
}

class LibraryState extends State<Library> {

  static ValueNotifier<int> deleting = ValueNotifier(-1);
  static Duration deleteDuration = Duration(milliseconds: 300);

  List<Widget> library() {
    allBooks.sort((a, b) => a.title.compareTo(b.title));
    List<Widget> output = [];
    Widget _container(BookProvider bookProvider, int index) {
      return FocusedMenuBook(
          index: index,
          bookProvider: bookProvider,
          child: ValueListenableBuilder<int>(
            valueListenable: deleting,
            builder: (context, value, _) {
              return AnimatedContainer(
                duration: deleteDuration,
                height: index == value ? 0 : MediaQuery.of(context).size.height * 0.2,
                margin: EdgeInsets.fromLTRB(7, MediaQuery.of(context).size.height * 0.0125, 7, MediaQuery.of(context).size.height * 0.0125),
                decoration: BoxDecoration(
                    color: Settings.colors[2],
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: Settings.theme.value == 'Dark'
                        ? [
                            BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.2),
                                blurRadius: 7,
                                spreadRadius: 1.5
                            )
                          ]
                        : [
                            BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.1),
                                blurRadius: 7,
                                spreadRadius: 0.1)
                          ]),
                child: SingleChildScrollView(
                  physics: NeverScrollableScrollPhysics(),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Content.contentNavigatorKey.currentState!.pushReplacementNamed('/bookPage', arguments: bookProvider);
                      },
                      highlightColor: Settings.colors[5],
                      splashColor: Settings.colors[5],
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Container(
                                        height: index == value ? 0 : MediaQuery.of(context).size.height * 0.2 - 20,
                                        child: Image.file(File(bookProvider.cover), fit: BoxFit.fill),
                                      );
                                    },
                                  )),
                            ),
                            Expanded(
                              flex: 3,
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    AutoSizeText(
                                      bookProvider.title,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 4,
                                      style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          color: Settings.colors[3]),
                                    ),
                                    AutoSizeText(
                                      bookProvider.author,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Settings.colors[4]),
                                    )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          )
      );
    }
    List<BookProvider> nonRead = allBooks.where((element) => element.status != 'read').toList();
    for (int i = 0; i < nonRead.length; i++){
      if (i == nonRead.length - 1) {
        output.add(Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.08 - MediaQuery.of(context).size.height * 0.0125),
          child: _container(nonRead[i], i),
        ));
      } else if (i == 0){
        output.add(Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.0125),
          child: _container(nonRead[i], i),
        ));
      } else {
        output.add(
          _container(nonRead[i], i)
        );
      }
    }
    return output;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: MediaQuery.of(context).size.width * 0.9 + 14,
        height: MediaQuery.of(context).size.height * 0.7,
        child: ScrollConfiguration(
            behavior: MyBehavior(),
            child: ValueListenableBuilder(
              valueListenable: booksChanged,
              builder: (context, value, _) {
                return ListView(
                  padding: EdgeInsets.zero,
                  children: library(),
                );
              },
            )
        )
    );
  }
}

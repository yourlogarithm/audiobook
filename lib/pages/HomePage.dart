import 'dart:io';
import 'package:audiobook/classes/book.dart';
import 'package:audiobook/classes/scrollBehavior.dart';
import 'package:audiobook/classes/settings.dart';
import 'package:audiobook/content.dart';
import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';

class HomePage extends StatefulWidget {
  // const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        : []),
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
                    Content.contentNavigatorKey.currentState!
                        .pushNamed('/addBook');
                    bottomBarIndex.value = -1;
                  },
                  elevation: 0,
                  backgroundColor: Settings.colors[6],
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ))
        ],
      ),
    );
  }
}

GlobalKey<AnimatedListState> animatedLibraryList =
    GlobalKey<AnimatedListState>();
ValueNotifier<bool> homeLibraryEditNotifier = ValueNotifier(false);

class Library extends StatefulWidget {
  @override
  _LibraryState createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  List<Widget> containers = [];

  List<Widget> library() {
    books.sort((a, b) => a.title.compareTo(b.title));
    List<Widget> output = [];
    FocusedMenuHolder _container(Book book, int index) {
      return FocusedMenuHolder(
        onPressed: () {},
        duration: Duration(milliseconds: 300),
        menuBoxDecoration: BoxDecoration(
            color: Settings.colors[2], borderRadius: BorderRadius.circular(5)),
        menuItems: [
          FocusedMenuItem(
              onPressed: () {
                bottomBarIndex.value = -1;
                Content.contentNavigatorKey.currentState!
                    .pushNamed('/changeCover', arguments: book);
              },
              trailingIcon:
                  Icon(Icons.image_outlined, color: Settings.colors[3]),
              title: Text(
                'Change cover',
                style: TextStyle(
                    color: Settings.colors[3],
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600),
              ),
              backgroundColor: Settings.colors[1]),
          FocusedMenuItem(
              onPressed: () {
                setState(() {
                  book.setDefaultCover();
                });
              },
              trailingIcon:
                  Icon(Icons.hide_image_outlined, color: Settings.colors[3]),
              title: Text(
                'Remove cover',
                style: TextStyle(
                    color: Settings.colors[3],
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600),
              ),
              backgroundColor: Settings.colors[1]),
          FocusedMenuItem(
              onPressed: () async {
                book.remove();
                setState(() {
                  animatedLibraryList.currentState!.removeItem(
                      index,
                      (context, animation) => SizeTransition(
                          sizeFactor: animation,
                          child: _container(book, index)));
                  containers.remove(book);
                });
              },
              trailingIcon:
                  Icon(Icons.delete_outlined, color: Color(0xffde4949)),
              title: Text(
                'Delete book',
                style: TextStyle(
                    color: Color(0xffde4949),
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600),
              ),
              backgroundColor: Settings.colors[1])
        ],
        child: Container(
          height: MediaQuery.of(context).size.height * 0.2,
          margin: EdgeInsets.fromLTRB(
              7,
              MediaQuery.of(context).size.height * 0.0125,
              7,
              MediaQuery.of(context).size.height * 0.0125),
          decoration: BoxDecoration(
              color: Settings.colors[2],
              borderRadius: BorderRadius.circular(20),
              boxShadow: Settings.theme.value == 'Dark'
                  ? [
                      BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.2),
                          blurRadius: 7,
                          spreadRadius: 1.5)
                    ]
                  : [
                      BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.1),
                          blurRadius: 7,
                          spreadRadius: 0.1)
                    ]),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                bottomBarIndex.value = -1;
                Content.contentNavigatorKey.currentState!.pushNamed(
                  '/bookPage',
                  arguments: book,
                );
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
                                height: constraints.maxHeight,
                                child: book.defaultCover
                                    ? Image.asset(
                                        book.cover,
                                        fit: BoxFit.fill,
                                      )
                                    : Image.file(File(book.cover),
                                        fit: BoxFit.fill),
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
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              book.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  color: Settings.colors[3]),
                            ),
                            Text(
                              book.author,
                              textAlign: TextAlign.center,
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
    }

    output = List.generate(books.length, (index) {
      return _container(books[index], index);
    });
    return output;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: homeLibraryEditNotifier,
        builder: (context, value, _) {
          containers = library();
          return Container(
              width: MediaQuery.of(context).size.width * 0.9 + 14,
              height: MediaQuery.of(context).size.height * 0.7,
              child: ScrollConfiguration(
                  behavior: MyBehavior(),
                  child: AnimatedList(
                      key: animatedLibraryList,
                      initialItemCount: containers.length,
                      itemBuilder: (context, index, animation) {
                        return containers[index];
                      })));
        });
  }
}

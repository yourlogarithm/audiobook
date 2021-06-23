import 'dart:io';
import 'package:audiobook/classes/book.dart';
import 'package:audiobook/classes/player.dart';
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
                      List<Book> foundLastListenedBook = books.where((book) => book.id == value).toList();
                      Book book;
                      if (foundLastListenedBook.isEmpty){
                        book = Book(id: -1, title: 'Start listening to an audiobook', author: '', checkpoint: Duration(seconds: 0), defaultCover: true, cover: Settings.dir.path + '/' 'defaultCover.png', length: Duration(seconds: 100), path: 'none', status: 'read');
                      } else {
                        book = foundLastListenedBook[0];
                      }
                      return GestureDetector(
                        onTap: () {
                          Content.contentNavigatorKey.currentState!.pushReplacementNamed('/bookPage', arguments: book);
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
                                            child: Image.file(File(book.cover), fit: BoxFit.fill)
                                        )
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.05),
                                        child: Text(
                                          book.title,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 4,
                                          style: TextStyle(
                                              color: Settings.colors[3],
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              HomePageTimeline(book: book)
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
                    // bottomBarIndex.value = -1;
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



GlobalKey<AnimatedListState> animatedLibraryList = GlobalKey<AnimatedListState>();
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
        menuBoxDecoration: BoxDecoration(color: Settings.colors[2], borderRadius: BorderRadius.circular(5)),
        menuItems: [
          FocusedMenuItem(
              onPressed: () {
                showDialog(context: context, builder: (context) {
                  TextEditingController _textController = TextEditingController(text: book.title);
                  return AlertDialog(
                      backgroundColor: Settings.colors[0],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      actionsPadding: EdgeInsets.fromLTRB(0, 0, 20, 5),
                      contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 12),
                      title: Text(
                        'Edit title',
                        style: TextStyle(
                            color: Settings.colors[3],
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600
                        ),
                      ),
                      content: TextField(
                        controller: _textController,
                        maxLength: 70,
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Settings.colors[3]
                        ),
                        decoration: InputDecoration(
                          hintText: 'Edit the title...',
                          hintStyle: TextStyle(
                              fontFamily: 'Montserrat',
                              color: Settings.colors[4]
                          ),
                          counterStyle: TextStyle(
                              fontFamily: 'Montserrat',
                              color: Settings.colors[4]
                          ),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(width: 2, color: Settings.colors[6])),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(width: 3, color: Settings.colors[6])),
                        ),
                      ),
                      actions: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                  color: Settings.colors[6],
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            if (_textController.text.length >= 1 && _textController.text[0] != ' '){
                              setState(() {
                                book.title = _textController.text;
                              });
                              book.update();
                            }
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              'Confirm',
                              style: TextStyle(
                                  color: Settings.colors[6],
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        )
                      ]
                  );
                });
              },
              trailingIcon: Icon(Icons.title, color: Settings.colors[3]),
              title: Text(
                'Edit title',
                style: TextStyle(
                    color: Settings.colors[3],
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600),
              ),
              backgroundColor: Settings.colors[1]
          ),
          FocusedMenuItem(
              onPressed: () {
                showDialog(context: context, builder: (context) {
                  TextEditingController _textController = TextEditingController(text: book.author);
                  return AlertDialog(
                      backgroundColor: Settings.colors[0],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      actionsPadding: EdgeInsets.fromLTRB(0, 0, 20, 5),
                      contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 12),
                      title: Text(
                        'Edit author',
                        style: TextStyle(
                            color: Settings.colors[3],
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600
                        ),
                      ),
                      content: TextField(
                        controller: _textController,
                        maxLength: 30,
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Settings.colors[3]
                        ),
                        decoration: InputDecoration(
                          hintText: 'Edit the author...',
                          hintStyle: TextStyle(
                              fontFamily: 'Montserrat',
                              color: Settings.colors[4]
                          ),
                          counterStyle: TextStyle(
                              fontFamily: 'Montserrat',
                              color: Settings.colors[4]
                          ),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(width: 2, color: Settings.colors[6])),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(width: 3, color: Settings.colors[6])),
                        ),
                      ),
                      actions: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                  color: Settings.colors[6],
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            if (_textController.text.length >= 1 && _textController.text[0] != ' '){
                              setState(() {
                                book.author = _textController.text;
                              });
                              book.update();
                            }
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              'Confirm',
                              style: TextStyle(
                                  color: Settings.colors[6],
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        )
                      ]
                  );
                });
              },
              trailingIcon: Icon(Icons.edit_outlined, color: Settings.colors[3]),
              title: Text(
                'Edit author',
                style: TextStyle(
                    color: Settings.colors[3],
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600),
              ),
              backgroundColor: Settings.colors[1]
          ),
          FocusedMenuItem(
              onPressed: () {
                Content.contentNavigatorKey.currentState!.pushReplacementNamed('/changeCover', arguments: book);
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
              backgroundColor: Settings.colors[1]
          ),
          FocusedMenuItem(
              onPressed: () {
                setState(() {
                  book.status = 'read';
                  animatedLibraryList.currentState!.removeItem(
                      index,
                      (context, animation) => SizeTransition(
                          sizeFactor: animation,
                          child: _container(book, index)
                      )
                  );
                  containers.remove(book);
                });
                book.update();
              },
              trailingIcon: Icon(Icons.done, color: Settings.colors[3]),
              title: Text(
                'Mark as read',
                style: TextStyle(
                    color: Settings.colors[3],
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600),
              ),
              backgroundColor: Settings.colors[1]
          ),
          FocusedMenuItem(
              onPressed: () {
                book.remove();
                setState(() {
                  animatedLibraryList.currentState!.removeItem(
                      index,
                      (context, animation) => SizeTransition(
                          sizeFactor: animation,
                          child: _container(book, index)
                      )
                  );
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
          margin: EdgeInsets.fromLTRB(7, MediaQuery.of(context).size.height * 0.0125, 7, MediaQuery.of(context).size.height * 0.0125),
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
                // bottomBarIndex.value = -1;
                Content.contentNavigatorKey.currentState!.pushReplacementNamed(
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
                                child: Image.file(File(book.cover), fit: BoxFit.fill),
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
                              overflow: TextOverflow.ellipsis,
                              maxLines: 4,
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  color: Settings.colors[3]),
                            ),
                            Text(
                              book.author,
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
    }

    List<Book> nonRead = books.where((element) => element.status != 'read').toList();
    for (int i = 0; i < nonRead.length; i++){
      if (i == 0) {
        output.add(Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.025),
          child: _container(nonRead[i], i),
        ));
      } else if (i == nonRead.length -1) {
        output.add(Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.0875),
          child: _container(nonRead[i], i),
        ));
      } else {
        output.add(_container(nonRead[i], i));
      }


    }
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
                      }
                  )
              )
          );
        });
  }
}

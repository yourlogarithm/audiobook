import 'dart:io';

import 'package:audiobook/classes/book.dart';
import 'package:audiobook/classes/scrollBehavior.dart';
import 'package:audiobook/classes/settings.dart';
import 'package:audiobook/content.dart';
import 'package:audiobook/pages/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';

class LibraryPage extends StatefulWidget{
  const LibraryPage({Key? key}) : super(key: key);

  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> with TickerProviderStateMixin  {

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Settings.colors[1],
      appBar: AppBar(
        brightness: Settings.theme.value == 'Dark' ? Brightness.dark : Brightness.light,
        shadowColor: Settings.theme.value == 'Dark' ? Color.fromRGBO(0, 0, 0, 0.1) : Color.fromRGBO(0, 0, 0, 0.5),
        backgroundColor: Settings.colors[2],
        title: Text('Library'),
        bottom: TabBar(
          controller: _tabController,
          // isScrollable: true,
          labelPadding: EdgeInsets.zero,
          labelStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500
          ),
          labelColor: Settings.colors[3],
          indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: Settings.colors[3], width: 2)
          ),
          tabs: [
            Tab(
              text: 'Reading',
            ),
            Tab(
              text: 'New',
            ),
            Tab(
              text: 'Read',
            )
          ],
        ),
      ),
      body: ScrollConfiguration(
        behavior: MyBehavior(),
        child: TabBarView(
          controller: _tabController,
          children: [
            Category(category: 'reading'),
            Category(category: 'new'),
            Category(category: 'read')
          ],
        ),
      ),
    );
  }
}

class Category extends StatefulWidget {
  final String category;
  const Category({required this.category});

  @override
  _CategoryState createState() => _CategoryState();
}

class _CategoryState extends State<Category> {

  List<Widget> getBooks() {
    List<Widget> output = [];
    books.forEach((book) {
      if (book.status == widget.category){
        output.add(
          Column(
            children: [
              Expanded(
                flex: 3,
                child: FocusedMenuHolder(
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
                        backgroundColor: Settings.colors[1]
                    ),
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
                            book.status = book.status == 'read' ? 'new' : 'read';
                          });
                          book.update();
                        },
                        trailingIcon: Icon(Icons.done, color: Settings.colors[3]),
                        title: Text(
                          book.status == 'read' ? 'Mark as unread' : 'Mark as read',
                          style: TextStyle(
                              color: Settings.colors[3],
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: Settings.colors[1]
                    ),
                    FocusedMenuItem(
                        onPressed: (){
                          setState(() {
                            book.remove();
                          });
                        },
                        trailingIcon: Icon(Icons.delete_outlined, color: Color(0xffde4949)),
                        title: Text(
                          'Delete book',
                          style: TextStyle(
                              color: Color(0xffde4949),
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: Settings.colors[1]
                    )
                  ],
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        width: constraints.maxWidth,
                        margin: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                        decoration: BoxDecoration(
                            color: Settings.colors[0],
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.1), spreadRadius: 1, blurRadius: 5)]
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            highlightColor: Settings.colors[5],
                            splashColor: Settings.colors[5],
                            onTap: () {
                              Content.contentNavigatorKey.currentState!.pushReplacementNamed('/bookPage', arguments: book);
                            },
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(File(book.cover), fit: BoxFit.fill)
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                ),
              ),
              Expanded(
                  flex: 1,
                  child: Center(
                      child: Text(
                        book.title,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Settings.colors[3],
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500
                        ),
                      )
                  )
              )
            ],
          )
        );
      }
    });
    return output;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.05, left: 10, right: 10, top: 10),
      physics: BouncingScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 0.75,
      children: getBooks(),
    );
  }
}




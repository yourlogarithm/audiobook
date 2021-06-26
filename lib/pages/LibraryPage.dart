import 'dart:io';
import 'package:audiobook/classes/book.dart';
import 'package:audiobook/classes/bookFocusedMenu.dart';
import 'package:audiobook/classes/scrollBehavior.dart';
import 'package:audiobook/classes/settings.dart';
import 'package:audiobook/content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LibraryPage extends StatefulWidget{
  const LibraryPage({Key? key}) : super(key: key);

  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> with TickerProviderStateMixin  {

  late TabController _tabController;
  late AppBar appBar;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    appBar = AppBar(
      brightness: Settings.theme.value == 'Dark' ? Brightness.dark : Brightness.light,
      shadowColor: Settings.theme.value == 'Dark' ? Color.fromRGBO(0, 0, 0, 0.1) : Color.fromRGBO(0, 0, 0, 0.5),
      backgroundColor: Settings.colors[2],
      title: Text(
        'Library',
        style: TextStyle(
          color: Settings.colors[3],
          fontFamily: 'Poppins'
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Settings.colors[1],
      resizeToAvoidBottomInset: false,
      appBar: appBar,
      body: ScrollConfiguration(
        behavior: MyBehavior(),
        child: Container(
          width: MediaQuery.of(context).size.width,
          color: Settings.colors[1],
          child: TabBarView(
            controller: _tabController,
            children: [
              Category(category: 'reading'),
              Category(category: 'new'),
              Category(category: 'read')
            ],
          ),
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
    books.where((element) => element.status == widget.category).forEach((book) {
        output.add(
          Column(
            children: [
              Expanded(
                flex: 3,
                child: FocusedMenuBook(
                  book: book,
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
                )
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
    });
    return output;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Settings.colors[1],
      child: ValueListenableBuilder(
        valueListenable: booksChanged,
        builder: (context, value, _) {
          List<Widget> _containers = getBooks();
          if (_containers.isNotEmpty){
            return GridView.count(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.05, left: 10, right: 10, top: 10),
              physics: BouncingScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              children: getBooks(),
            );
          } else {
            return Center(
              child: Text(
                'Empty',
                style: TextStyle(
                  color: Settings.colors[3],
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500
                ),
              ),
            );
          }
        },
      )
    );
  }
}




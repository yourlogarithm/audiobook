import 'dart:async';
import 'package:audiobook/classes/book.dart';
import 'package:audiobook/classes/settings.dart';
import 'package:audiobook/content.dart';
import 'package:audiobook/pages/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';

class FocusedMenuBook extends StatefulWidget {
  final BookProvider bookProvider;
  final int index;
  final Widget child;
  const FocusedMenuBook({required this.bookProvider, required this.child, required this.index});

  @override
  _FocusedMenuBookState createState() => _FocusedMenuBookState();
}

class _FocusedMenuBookState extends State<FocusedMenuBook> {
  @override
  Widget build(BuildContext context) {
    return FocusedMenuHolder(
        onPressed: () {},
        duration: Duration(milliseconds: 300),
        menuBoxDecoration: BoxDecoration(color: Settings.colors[2], borderRadius: BorderRadius.circular(5)),
        menuItems: [
          FocusedMenuItem(
              onPressed: () {
                showDialog(context: context, builder: (context) {
                  TextEditingController _textController = TextEditingController(text: widget.bookProvider.title);
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
                                widget.bookProvider.changeTitle(_textController.text);
                              });
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
                  TextEditingController _textController = TextEditingController(text: widget.bookProvider.author);
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
                                  fontWeight: FontWeight.w600
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            if (_textController.text.length >= 1 && _textController.text[0] != ' '){
                              setState(() {
                                widget.bookProvider.changeAuthor(_textController.text);
                              });
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
                Content.contentNavigatorKey.currentState!.pushReplacementNamed('/changeCover', arguments: widget.bookProvider);
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
                  widget.bookProvider.setDefaultCover();
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
                LibraryState.deleting.value = widget.index;
                Timer(Duration(milliseconds: 300), () {
                  LibraryState.deleteDuration = Duration.zero;
                  setState(() {
                    widget.bookProvider.changeStatus(widget.bookProvider.status == 'read' ? 'new' : 'read');
                    widget.bookProvider.update();
                    LibraryState.deleting.value = -1;
                  });
                  Timer(Duration(milliseconds: 300), () {
                    LibraryState.deleteDuration = Duration(milliseconds: 300);
                  });
                });
              },
              trailingIcon: Icon(Icons.done, color: Settings.colors[3]),
              title: Text(
                'Mark as ${widget.bookProvider.status == 'read' ? 'new' : 'read'}',
                style: TextStyle(
                    color: Settings.colors[3],
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600),
              ),
              backgroundColor: Settings.colors[1]
          ),
          FocusedMenuItem(
              onPressed: () {
                LibraryState.deleting.value = widget.index;
                Timer(Duration(milliseconds: 300), () {
                  LibraryState.deleteDuration = Duration.zero;
                  setState(() {
                    widget.bookProvider.remove();
                    LibraryState.deleting.value = -1;
                  });
                  Timer(Duration(milliseconds: 300), () {
                    LibraryState.deleteDuration = Duration(milliseconds: 300);
                  });
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
        child: widget.child
    );
  }
}

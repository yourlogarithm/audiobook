import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:audiobook/classes/book.dart';
import 'package:audiobook/classes/bookmark.dart';
import 'package:audiobook/classes/database.dart';
import 'package:audiobook/classes/player.dart';
import 'package:audiobook/classes/scrollBehavior.dart';
import 'package:audiobook/classes/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

ValueNotifier<Widget> bookPageContextMenu = ValueNotifier(Container());

class BookPage extends StatefulWidget {
  final Book book;
  const BookPage({required this.book});

  @override
  _BookPageState createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              bookPageContextMenu.value = Container();
            },
            child: ValueListenableBuilder(
              valueListenable: bookPageContextMenu,
              builder: (context, value, _) {
                double amount = 0;
                if (value.runtimeType != Container){
                  amount = 0.7;
                }
                return ColorFiltered(
                  colorFilter: ColorFilter.mode(Color.fromRGBO(0, 0, 0, amount), BlendMode.darken),
                  child: Container(
                    color: Settings.colors[1],
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.025),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(15),
                                    width: MediaQuery.of(context).size.width * 0.8,
                                    height: MediaQuery.of(context).size.width * 0.8,
                                    decoration: BoxDecoration(
                                        color: Settings.colors[0],
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: Settings.theme.value == 'Dark'
                                        ? [
                                        BoxShadow(
                                            color: Color.fromRGBO(0, 0, 0, 0.1),
                                            spreadRadius: 1,
                                            blurRadius: 5)
                                        ]
                                            : []),
                                    child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: LayoutBuilder(
                                          builder: (layoutcontext, constraints) {
                                            return Container(
                                              height: constraints.maxHeight,
                                              child: Image.file(File(widget.book.cover), fit: BoxFit.fill),
                                            );
                                          },
                                        )),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 20),
                                    child: Timeline(book: widget.book),
                                  ),
                                ],
                              ),
                              AnimatedContainer(
                                duration: Duration(milliseconds: 500),
                                child: Column(
                                  children: [
                                    Text(widget.book.author,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 16,
                                            color: Settings.colors[4])),
                                    Text(
                                      widget.book.title,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Settings.colors[3],
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20),
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width * 0.9,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    BookmarkIcon(book: widget.book),
                                    SleepTimerIcon(),
                                    Lock()
                                  ],
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
            ),
          ),
          Positioned(
            width: MediaQuery.of(context).size.width * 0.6,
            // height: MediaQuery.of(context).size.height * 0.25,
            left: MediaQuery.of(context).size.width * 0.05,
            bottom: MediaQuery.of(context).size.height * 0.1,
            child: ValueListenableBuilder<Widget>(
                valueListenable: bookPageContextMenu,
                builder: (context, value, _) {
                  return AnimatedSwitcher(duration: Duration(milliseconds: 500), child: value);
                }
            ),
          )
        ],
      ),
    );
  }
}

class Timeline extends StatefulWidget {
  final Book book;
  Timeline({required this.book});

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  double buttonsTopPadding = 0.025;
  double buttonsHeight = 0.075;
  double buttonsOpacity = 1;

  Widget timelineControlButton(IconData icon, Function function) {
    return InkWell(
      customBorder: CircleBorder(),
      onTap: () {
      bookPageContextMenu.value = Container();
        function();
      },
      child: Icon(icon, color: Settings.colors[3], size: 42),
    );
  }
  int amount = 0;
  @override
  Widget build(BuildContext context) {
    double _width = MediaQuery.of(context).size.width * 0.8;
    return Container(
      width: _width,
      child: StreamBuilder<Duration>(
        stream: AudioService.positionStream,
        builder: (context, snapshot) {
          Duration _position = widget.book.checkpoint;
          if (snapshot.hasData && AudioService.playbackState.playing && playerUrl == widget.book.path && AudioService.running){
            AudioService.customAction('pposition').then((value) {
              if (value != null) {
                _position = Duration(seconds: value);
                widget.book.checkpoint = _position;
                if (_position >= widget.book.length){
                  AudioService.seekTo(widget.book.length);
                  AudioService.stop();
                }
              }
            });
            widget.book.update();
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                          convertDuration(_position),
                          style: TextStyle(
                              color: Settings.colors[4], fontFamily: 'Poppins'),
                    ),
                    Text(
                      convertDuration(widget.book.length),
                      style: TextStyle(
                          color: Settings.colors[4], fontFamily: 'Poppins'
                      ),
                    )
                  ],
                ),
              ),
              Container(
                height: 20,
                child: Stack(
                  children: [
                    Container(
                      width: _width,
                      child: CustomPaint(
                        foregroundPainter: TimelinePainter(Settings.colors[5], _width),
                      ),
                    ),
                    Container(
                      width: _width,
                      child: CustomPaint(
                        foregroundPainter: TimelinePainter(Settings.colors[6], (_position.inSeconds * _width) / widget.book.length.inSeconds),
                      ),
                    ),
                    Positioned(
                      left: (_position.inSeconds * _width) / widget.book.length.inSeconds - 25,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            widget.book.checkpoint = Duration(seconds: ((details.globalPosition.dx / MediaQuery.of(context).size.width) * widget.book.length.inSeconds).round());
                          });
                          if (AudioService.running) {
                            AudioService.seekTo(widget.book.checkpoint).whenComplete(() => setState(() {}));
                          }
                        },
                        onPanEnd: (details) {
                          widget.book.update();
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: CustomPaint(
                            size: Size(50, 20),
                            foregroundPainter: TimelinePositionCirclePainter(25),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              ValueListenableBuilder<bool>(
                  valueListenable: _isLocked,
                  builder: (context, value, _) {
                    if (value) {
                      buttonsTopPadding = 0;
                      buttonsHeight = 0;
                      buttonsOpacity = 0;
                    } else {
                      buttonsTopPadding = 0.005;
                      buttonsHeight = 0.075;
                      buttonsOpacity = 1;
                    }
                    return AnimatedContainer(
                      height: MediaQuery.of(context).size.height * buttonsHeight,
                      padding: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height * buttonsTopPadding),
                      duration: Duration(milliseconds: 500),
                      child: AnimatedOpacity(
                        opacity: buttonsOpacity,
                        duration: Duration(milliseconds: 500),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              !value
                                  ? timelineControlButton(
                                      Icons.skip_previous_outlined, () {})
                                  : Container(),
                              !value
                                  ? timelineControlButton(
                                      Icons.fast_rewind_outlined, () {
                                        setState(() {
                                          forwardRewind(widget.book, forward: false);
                                        });
                                  })
                                  : Container(),
                              !value
                                  ? StreamBuilder<PlaybackState>(
                                      stream: AudioService.playbackStateStream,
                                      builder: (context, snapshot) {
                                        IconData icon = Icons.play_arrow;
                                        if (snapshot.hasData) {
                                          if (snapshot.data!.playing && playerUrl == widget.book.path) {
                                            icon = Icons.pause;
                                          }
                                        }
                                        return timelineControlButton(icon, () {
                                          playBook(widget.book);
                                        });
                                      })
                                  : Container(),
                              !value
                                  ? timelineControlButton(
                                      Icons.fast_forward_outlined, () {
                                        setState(() {
                                          forwardRewind(widget.book, forward: true);
                                        });
                                      })
                                  : Container(),
                              !value
                                  ? timelineControlButton(
                                      Icons.skip_next_outlined, () {})
                                  : Container(),
                            ]),
                      ),
                    );
                  })
            ],
          );
        }
      ),
    );
  }
}

class TimelinePainter extends CustomPainter {
  late Color color;
  late double x;

  TimelinePainter(Color ccolor, double cx) {
    color = ccolor;
    x = cx;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(0, 10), Offset(x, 10), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class TimelinePositionCirclePainter extends CustomPainter {
  late double x;

  TimelinePositionCirclePainter(double arg) {
    x = arg;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Settings.colors[6];
    canvas.drawCircle(Offset(x, 10), 5.5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

GlobalKey bookmarkIconKey = GlobalKey();

class BookmarkIcon extends StatefulWidget {
  final Book book;
  BookmarkIcon({required this.book});
  @override
  _BookmarkIconState createState() => _BookmarkIconState();
}

class _BookmarkIconState extends State<BookmarkIcon>
    with SingleTickerProviderStateMixin {
  bool active = false;

  IconData icon = Icons.timer;
  Color color = Settings.colors[3];

  late AnimationController _animationController;
  late Animation<Color?> _colorTween;
  double filledBookmarkIconOpacity = 0;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _colorTween = ColorTween(begin: Settings.colors[3], end: Settings.colors[5]).animate(_animationController);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
  }

  void addBookmark() async {
    if (!active) {
      Bookmark bookmark = Bookmark(
          bookTitle: widget.book.title,
          title: convertDuration(widget.book.checkpoint),
          time: widget.book.checkpoint
      );
      bookmark.insert();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: Duration(seconds: 1),
          backgroundColor: Settings.colors[6],
          content: Text(
            'Bookmark added',
            style: TextStyle(
                fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
          )));
      active = true;
      _animationController.animateTo(100);
      setState(() {
        filledBookmarkIconOpacity = 1;
      });
      Timer(Duration(seconds: 1), () {
        _animationController.animateTo(0);
        setState(() {
          filledBookmarkIconOpacity = 0;
        });
      });
      Timer(Duration(seconds: 5), () {
        active = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          bookPageContextMenu.value = Container();
          addBookmark();
        });
      },
      onLongPress: () {
        DatabaseProvider.getBookmarks(widget.book.title).then((value) {
          if (value.isNotEmpty) {
            setState(() {
              bookPageContextMenu.value = ContextMenu(context: context, book: widget.book);
            });
          }
        });
      },
      child: Stack(
        key: bookmarkIconKey,
        children: [
          AnimatedBuilder(
            animation: _colorTween,
            builder: (context, child) {
              return Icon(Icons.bookmark_outline, color: _colorTween.value, size: 42);
              },
          ),
          AnimatedOpacity(
            opacity: filledBookmarkIconOpacity,
            duration: Duration(milliseconds: 300),
            child: Icon(Icons.bookmark, color: Settings.colors[5], size: 42),
          ),
        ],
      ),
    );
  }
}

class ContextMenu extends StatefulWidget {
  final BuildContext context;
  final Book book;
  const ContextMenu({required this.context, required this.book});

  @override
  _ContextMenuState createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> {

  TextEditingController _textEditingController = TextEditingController();

  Future<List<Widget>> getBookmarks() async {
    List<Bookmark> bookmarks = await DatabaseProvider.getBookmarks(widget.book.title);
    List<Widget> output = [];
    bookmarks.sort((a, b) => b.time.compareTo(a.time));
    for (int i = 0; i < bookmarks.length; i++){
      BoxDecoration decoration = BoxDecoration(color: Settings.colors[0]);
      BorderRadius radius = BorderRadius.circular(0);
      if (bookmarks.length == 1) {
        radius = BorderRadius.circular(10);
      } else if (i == 0){
        radius = BorderRadius.vertical(top: Radius.circular(10));
      } else if (i == bookmarks.length-1) {
        radius = BorderRadius.vertical(bottom: Radius.circular(10));
      }
      decoration = BoxDecoration(
          color: Settings.colors[0],
          borderRadius: radius
      );
      output.add(
          Container(
            decoration: decoration,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: radius,
                onTap: () {
                  widget.book.checkpoint = bookmarks[i].time;
                  if (AudioService.running){
                    AudioService.seekTo(bookmarks[i].time);
                  }
                  widget.book.update();
                  setState(() {
                    bookPageContextMenu.value = Container();
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          bookmarks[i].title,
                          style: TextStyle(
                              color: Settings.colors[3],
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w500
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(widget.context).size.width * 0.2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ClipOval(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    _textEditingController.text = bookmarks[i].title;
                                    showDialog(context: context, builder: (context) {
                                      return AlertDialog(
                                        backgroundColor: Settings.colors[0],
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                        actionsPadding: EdgeInsets.fromLTRB(0, 0, 20, 5),
                                        contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 12),
                                        title: Text(
                                          'Bookmark name',
                                          style: TextStyle(
                                              color: Settings.colors[3],
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600),
                                        ),
                                        content: TextField(
                                          controller: _textEditingController,
                                          maxLength: 30,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            color: Settings.colors[3]
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Edit your bookmark name...',
                                            hintStyle: TextStyle(
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
                                              String bookmarkTitle = _textEditingController.text;
                                              if (bookmarkTitle.isNotEmpty){
                                                bookmarks[i].title = bookmarkTitle;
                                                bookmarks[i].update();
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
                                                    fontWeight: FontWeight.w600
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      );
                                    }).whenComplete(() {
                                      setState(() {
                                        bookPageContextMenu.value = Container();
                                      });
                                    });
                                  },
                                  child: Icon(Icons.edit, color: Settings.colors[4], size: 26),
                                ),
                              ),
                            ),
                            ClipOval(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      bookmarks[i].remove().then((value){
                                        if (value.isEmpty) {
                                          setState(() {
                                            bookPageContextMenu.value = Container();
                                          });
                                        }
                                      });
                                    });
                                  },
                                  child: Icon(Icons.delete, color: Color(0xffde4949),  size: 26),
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
      );
    }
    return output;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Widget>>(
        future: getBookmarks(),
        builder: (context, snapshot){
          if (snapshot.hasData){
            if (snapshot.data!.isNotEmpty){
              return Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
                  decoration: BoxDecoration(
                    color: Settings.colors[2],
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: ScrollConfiguration(
                    behavior: MyBehavior(),
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 1,
                      childAspectRatio: 4,
                      mainAxisSpacing: 1,
                      padding: EdgeInsets.all(0),
                      children: snapshot.data!,
                    ),
                  )
              );
            } else {
              return Container();
            }
          } else {
            return Container();
          }
        }
    );
  }
}


class SleepTimerIcon extends StatefulWidget {
  // const SleepTimerIcon({Key key}) : super(key: key);

  @override
  _SleepTimerIconState createState() => _SleepTimerIconState();
}

class _SleepTimerIconState extends State<SleepTimerIcon>
    with SingleTickerProviderStateMixin {
  Color color = Settings.colors[3];

  late AnimationController _animationController;
  late Animation<Color?> _colorTween;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _colorTween = ColorTween(begin: Settings.colors[3], end: Settings.colors[5]).animate(_animationController);
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _colorTween,
        builder: (context, child) {
          return GestureDetector(
              onTap: () {
                bookPageContextMenu.value = Container();
                setSleep();
              },
              child: ValueListenableBuilder<bool>(
                valueListenable: sleep,
                builder: (context, value, _) {
                  if (value) {
                    _animationController.animateTo(100);
                  } else {
                    _animationController.animateTo(0);
                  }
                  return Icon(Icons.timer, color: _colorTween.value, size: 42);
                }
              )
          );
        });
  }
}

ValueNotifier<bool> _isLocked = ValueNotifier(false);

class Lock extends StatefulWidget {
  // const Lock({Key key}) : super(key: key);

  @override
  _LockState createState() => _LockState();
}

class _LockState extends State<Lock> with SingleTickerProviderStateMixin {
  Color color = Settings.colors[3];
  late AnimationController _animationController;
  late Animation<Color?> _colorTween;
  IconData icon = Icons.lock_open;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _colorTween = ColorTween(begin: Settings.colors[3], end: Settings.colors[5]).animate(_animationController);
    if (_isLocked.value) {
      icon = Icons.lock_outline;
      _animationController.animateTo(100);
    }
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorTween,
      builder: (context, child) {
        return GestureDetector(
            onTap: () {
              bookPageContextMenu.value = Container();
              _isLocked.value = !_isLocked.value;
              if (_isLocked.value) {
                _animationController.animateTo(100);
                setState(() {
                  icon = Icons.lock_outline;
                });
              } else {
                _animationController.animateTo(0);
                setState(() {
                  icon = Icons.lock_open;
                });
              }
            },
            child: Icon(icon, color: _colorTween.value, size: 42));
      },
    );
  }
}

String convertDuration(Duration duration) {
  String inHours = duration.inHours.toString();
  String inMinutes = (duration.inMinutes % 60).toString();
  String inSeconds = (duration.inSeconds % 60).toString();
  List<String> time = [inHours, inMinutes, inSeconds];
  for (int i = 0; i < time.length; i++) {
    if (time[i].length == 1) {
      time[i] = '0' + time[i];
    }
  }
  return time[0] == '00'
      ? '${time[1]}:${time[2]}'
      : '${time[0]}:${time[1]}:${time[2]}';
}

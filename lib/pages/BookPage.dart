import 'dart:async';
import 'dart:io';
import 'package:audiobook/classes/book.dart';
import 'package:audiobook/classes/bookmark.dart';
import 'package:audiobook/classes/database.dart';
import 'package:audiobook/classes/settings.dart';
import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';

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
      backgroundColor: Settings.colors[1],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.height * 0.025),
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
                                child: widget.book.defaultCover
                                    ? Image.asset(widget.book.cover,
                                        fit: BoxFit.fill)
                                    : Image.file(File(widget.book.cover),
                                        fit: BoxFit.fill),
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
      onTap: () => function(),
      child: Icon(icon, color: Settings.colors[3], size: 42),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  convertDuration(widget.book.checkpoint),
                  style: TextStyle(
                      color: Settings.colors[4], fontFamily: 'Poppins'),
                ),
                Text(
                  convertDuration(widget.book.length),
                  style: TextStyle(
                      color: Settings.colors[4], fontFamily: 'Poppins'),
                )
              ],
            ),
          ),
          Stack(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.85,
                child: CustomPaint(
                  foregroundPainter: TimelinePainter(Settings.colors[5],
                      MediaQuery.of(context).size.width * 0.85),
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.85,
                child: CustomPaint(
                  foregroundPainter: TimelinePainter(Settings.colors[6], 0),
                ),
              ),
              CustomPaint(
                foregroundPainter: TimelinePositionCirclePainter(0),
              )
            ],
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
                      top: MediaQuery.of(context).size.height *
                          buttonsTopPadding),
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
                                  Icons.fast_rewind_outlined, () {})
                              : Container(),
                          !value
                              ? timelineControlButton(
                                  Icons.skip_previous_outlined, () {})
                              : Container(),
                          !value
                              ? timelineControlButton(
                                  Icons.fast_forward_outlined, () {})
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
    canvas.drawLine(Offset(0, 0), Offset(x, 0), paint);
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
    canvas.drawCircle(Offset(x, 0), 5.5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

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
  late Timer sleepTimer;
  Color color = Settings.colors[3];

  late AnimationController _animationController;
  late Animation<Color?> _colorTween;
  double filledBookmarkIconOpacity = 0;

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _colorTween = ColorTween(begin: Settings.colors[3], end: Settings.colors[5])
        .animate(_animationController);
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
          time: widget.book.checkpoint);
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

  Future<List<FocusedMenuItem>> getBookmarks() async {
    List<Bookmark> bookmarks =
        await DatabaseProvider.getBookmarks(widget.book.title);
    List<FocusedMenuItem> output = [];
    bookmarks.sort((a, b) => b.time.compareTo(a.time));
    bookmarks.forEach((bookmark) {
      output.add(FocusedMenuItem(
          onPressed: () {},
          backgroundColor: Settings.colors[1],
          title: Container(
            width: MediaQuery.of(context).size.width * 0.5 - 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bookmark.title,
                  style: TextStyle(
                      color: Settings.colors[3],
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600),
                ),
                ClipOval(
                  child: Material(
                    color: Colors.transparent,
                    child: ClipOval(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            bookmarks.remove(bookmark);
                          });
                          Navigator.pop(context);
                          bookmark.remove();
                        },
                        child: Icon(Icons.delete_outlined,
                            color: Color(0xffde4949), size: 26),
                      ),
                    ),
                  ),
                )
              ],
            ),
          )));
    });
    return output;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FocusedMenuItem>>(
        future: getBookmarks(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return FocusedMenuHolder(
                menuWidth: MediaQuery.of(context).size.width * 0.5,
                onPressed: () {},
                duration: Duration(milliseconds: 300),
                menuBoxDecoration: BoxDecoration(
                    color: Settings.colors[2],
                    borderRadius: BorderRadius.circular(5)),
                menuItems: snapshot.data!,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      addBookmark();
                    });
                  },
                  child: Stack(
                    children: [
                      AnimatedBuilder(
                        animation: _colorTween,
                        builder: (context, child) {
                          return Icon(Icons.bookmark_outline,
                              color: _colorTween.value, size: 42);
                        },
                      ),
                      AnimatedOpacity(
                        opacity: filledBookmarkIconOpacity,
                        duration: Duration(milliseconds: 300),
                        child: Icon(Icons.bookmark,
                            color: Settings.colors[5], size: 42),
                      )
                    ],
                  ),
                ));
          } else {
            return Container();
          }
        });
  }
}

bool _sleepActive = false;

class SleepTimerIcon extends StatefulWidget {
  // const SleepTimerIcon({Key key}) : super(key: key);

  @override
  _SleepTimerIconState createState() => _SleepTimerIconState();
}

class _SleepTimerIconState extends State<SleepTimerIcon>
    with SingleTickerProviderStateMixin {
  Timer? sleepTimer;
  Color color = Settings.colors[3];

  late AnimationController _animationController;
  late Animation<Color?> _colorTween;

  void setSleep() {
    // sleepTimer = Timer(Duration(minutes: Settings.sleepTimer), () {
    //   if (AudioService.playbackState.playing){
    //     DatabaseProvider.updateAudiobook(contentAudiobook.value);
    //     AudioService.stop();
    //   }
    //   _animationController.animateTo(0);
    // });
  }

  void cancelSleep() {
    // if (sleepTimer != null ){
    //   sleepTimer!.cancel();
    // }
  }

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _colorTween = ColorTween(begin: Settings.colors[3], end: Settings.colors[5])
        .animate(_animationController);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _colorTween,
        builder: (context, child) {
          return GestureDetector(
              onTap: () {
                _sleepActive = !_sleepActive;
                if (_sleepActive) {
                  setSleep();
                  _animationController.animateTo(100);
                } else {
                  cancelSleep();
                  _animationController.animateTo(0);
                }
              },
              child: Icon(Icons.timer, color: _colorTween.value, size: 42));
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
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _colorTween = ColorTween(begin: Settings.colors[3], end: Settings.colors[5])
        .animate(_animationController);
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

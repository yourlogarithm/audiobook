import 'dart:async';
import 'package:audiobook/classes/book.dart';
import 'package:audiobook/classes/settings.dart';
import 'package:audiobook/pages/BookPage.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

String playerUrl = '';

ValueNotifier<bool> sleep = ValueNotifier(false);
late Timer sleepTimer;
Timer? forceStopTimer;

backgroundTaskEntrypoint() {
  AudioServiceBackground.run(() => MyAudioPlayerTask());
}


void playBook(Book book) async {
  Future<void> _start() async {
    playerUrl = book.path;
    Settings.lastListenedBook.value = book.id!;
    Settings.write();
    await AudioService.start(backgroundTaskEntrypoint: backgroundTaskEntrypoint, params: book.toMap(), fastForwardInterval: Settings.forceStop, rewindInterval: Settings.rewind);
    if (book.status == 'new' || book.status == 'read') {
      book.status = 'reading';
      book.update();
    }
    if (book.checkpoint.value != book.length) {
      await AudioService.seekTo(book.checkpoint.value);
    } else {
      await AudioService.seekTo(Duration(seconds: 0));
    }
  }
  if (AudioService.running) {
    if (AudioService.playbackState.playing && playerUrl == book.path) {
      AudioService.pause();
    } else {
      if (playerUrl == book.path) {
        AudioService.play();
      } else {
        await AudioService.stop();
        _start();
      }
    }
  } else {
    _start();
  }
}

void forwardRewind(Book book, {bool forward = false}){
  Duration edited = forward ? book.checkpoint.value+Settings.rewind : book.checkpoint.value-Settings.rewind;
  if (edited < Duration(seconds: 0)) {
    edited = Duration(seconds: 0);
  } else if (edited > book.length){
    edited = book.length;
  }
  book.checkpoint.value = edited;
  if (AudioService.running){
    forward ? AudioService.fastForward(): AudioService.rewind();
  }
  book.update();
}
void nextPreviousChapter(Book book, {bool next = false}) {
  if (next){
    if (book.nowChapter != book.chapters.last){
      Duration _position = book.chapters[book.chapters.indexOf(book.nowChapter)+1].start;
      AudioService.seekTo(_position);
      book.checkpoint.value = _position;
    }
  } else {
    if (book.nowChapter != book.chapters.first){
      Duration _position = book.chapters[book.chapters.indexOf(book.nowChapter)-1].start;
      AudioService.seekTo(_position);
      book.checkpoint.value = _position;
    }
  }
}
void setSleep() {
  if (!sleep.value) {
    sleepTimer = Timer(Settings.sleep, () {
      sleep.value = false;
      if (AudioService.running) {
        AudioService.stop();
      }
    });
  } else {
    sleepTimer.cancel();
  }
  sleep.value = !sleep.value;
}

class MyAudioPlayerTask extends BackgroundAudioTask {
  static AudioPlayer player = AudioPlayer();
  @override
  Future<void> onStart(Map<String, dynamic>? params) async {
    if (forceStopTimer != null){
      forceStopTimer!.cancel();
    }
    AudioServiceBackground.setState(
        controls: [MediaControl.rewind, MediaControl.pause, MediaControl.fastForward],
        playing: true,
        processingState: AudioProcessingState.connecting
    );
    await player.setUrl(params!['path']);
    player.play();
    MediaItem item = MediaItem(id: params['path'], album: params['author'], title: params['title'], artUri: Uri.file(params['cover']));
    await AudioServiceBackground.setMediaItem(item);
    AudioServiceBackground.setState(
        controls: [MediaControl.rewind, MediaControl.pause, MediaControl.fastForward],
        playing: true,
        processingState: AudioProcessingState.ready
    );
    forceStopTimer = Timer(fastForwardInterval, () {
      AudioService.pause();
    });
  }

  @override
  Future<void> onStop() async {
    await AudioServiceBackground.setState(
        controls: [],
        playing: false,
        processingState: AudioProcessingState.stopped
    );
    await player.stop();
    return super.onStop();
  }

  @override
  Future<void> onPlay() {
    if (forceStopTimer != null) {
      forceStopTimer!.cancel();
    }
    player.play();
    AudioServiceBackground.setState(
        controls: [MediaControl.rewind, MediaControl.pause, MediaControl.fastForward],
        playing: true,
        processingState: AudioProcessingState.ready
    );
    forceStopTimer = Timer(fastForwardInterval, () {
      AudioService.pause();
    });
    return super.onPlay();
  }

  @override
  Future<void> onPause() {
    player.pause();
    AudioServiceBackground.setState(
        controls: [MediaControl.play, MediaControl.stop],
        playing: false,
        processingState: AudioProcessingState.ready
    );
    return super.onPause();
  }

  @override
  Future<void> onSeekTo(Duration position) async {
    await player.seek(position);
  }

  @override
  Future<void> onRewind() async {
    await player.seek(player.position - rewindInterval);
  }

  @override
  Future<void> onFastForward() async {
    await player.seek(player.position + rewindInterval);
  }

  @override
  Future onCustomAction(String name, arguments) async {
    switch(name) {
      case 'pposition':
        return player.position.inSeconds;
    }
    return super.onCustomAction(name, arguments);
  }
}

Widget _timelineControlButton(IconData icon, Function function) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      customBorder: CircleBorder(),
      onTap: () {
        bookPageContextMenu.value = Container();
        function();
      },
      child: Icon(icon, color: Settings.colors[3], size: 42),
    ),
  );
}

class HomePageTimeline extends StatefulWidget {
  final Book book;
  const HomePageTimeline({required this.book});

  @override
  _HomePageTimelineState createState() => _HomePageTimelineState();
}

class _HomePageTimelineState extends State<HomePageTimeline> {
  @override
  Widget build(BuildContext context) {
    double _width = MediaQuery.of(context).size.width * 0.9;
    return StreamBuilder<Duration>(
        stream: AudioService.positionStream,
        builder: (context, snapshot) {
          Duration _position = widget.book.checkpoint.value;
          if (snapshot.hasData && AudioService.playbackState.playing && playerUrl == widget.book.path && AudioService.running){
            AudioService.customAction('pposition').then((value) {
              if (value != null) {
                _position = Duration(seconds: value);
                widget.book.checkpoint.value = _position;
                if (_position >= widget.book.length){
                  AudioService.seekTo(widget.book.length);
                  widget.book.status = 'read';
                  widget.book.update();
                  AudioService.stop();
                }
              }
            });
            widget.book.update();
          }
          return Column(
            children: [
              SizedBox
                (
                height: 20,
                child: Stack(
                  overflow: Overflow.visible,
                  children: [
                    SizedBox(
                      width: _width,
                      child: CustomPaint(
                        foregroundPainter: TimelinePainter(Settings.colors[5], _width),
                      ),
                    ),
                    SizedBox(
                      width: _width,
                      child: CustomPaint(
                        foregroundPainter: TimelinePainter(Settings.colors[6], (_position.inSeconds * _width) / widget.book.length.inSeconds),
                      ),
                    ),
                    Positioned(
                      left: (_position.inSeconds * _width) / widget.book.length.inSeconds - 25,
                      width: 50,
                      height: 50,
                      child: Container(
                        color: Colors.transparent,
                        child: CustomPaint(
                          size: Size(50, 20),
                          foregroundPainter: TimelinePositionCirclePainter(25),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                width: _width,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _timelineControlButton(Icons.skip_previous_outlined, () {
                        setState(() {
                          nextPreviousChapter(widget.book);
                        });
                      }),
                      _timelineControlButton(Icons.fast_rewind_outlined, () {
                        if (widget.book.id != -1) {
                          setState(() {
                            forwardRewind(widget.book, forward: false);
                          });
                        }
                      }),
                      widget.book.id != -1 ? StreamBuilder<PlaybackState>(
                          stream: AudioService.playbackStateStream,
                          builder: (context, snapshot) {
                            IconData icon = Icons.play_arrow;
                            if (snapshot.hasData) {
                              if (snapshot.data!.playing && playerUrl == widget.book.path) {
                                icon = Icons.pause;
                              }
                            }
                            return _timelineControlButton(icon, () {
                              playBook(widget.book);
                            });
                          }
                      ) : _timelineControlButton(Icons.play_arrow, () {}),
                      _timelineControlButton(Icons.fast_forward_outlined, () {
                        if (widget.book.id != -1) {
                          setState(() {
                            forwardRewind(widget.book, forward: true);
                          });
                        }
                      }),
                      _timelineControlButton(Icons.skip_next_outlined, () {
                        setState(() {
                          nextPreviousChapter(widget.book, next: true);
                        });
                      })
                    ]
                ),
              ),
            ]);
        });
  }
}


class BookPageTimeline extends StatefulWidget {
  final Book book;
  BookPageTimeline({required this.book});

  @override
  _BookPageTimelineState createState() => _BookPageTimelineState();
}

class _BookPageTimelineState extends State<BookPageTimeline> {
  double buttonsTopPadding = 0.025;
  double buttonsHeight = 0.075;
  double buttonsOpacity = 1;

  @override
  Widget build(BuildContext context) {
    double _width = MediaQuery.of(context).size.width * 0.8;
    return Container(
      width: _width,
      child: StreamBuilder<Duration>(
          stream: AudioService.positionStream,
          builder: (context, snapshot) {
            Duration _position = widget.book.checkpoint.value;
            if (snapshot.hasData && AudioService.playbackState.playing && playerUrl == widget.book.path && AudioService.running){
              AudioService.customAction('pposition').then((value) {
                if (value != null) {
                  _position = Duration(seconds: value);
                  widget.book.checkpoint.value = _position;
                  if (_position >= widget.book.length){
                    AudioService.seekTo(widget.book.length);
                    widget.book.status = 'read';
                    widget.book.update();
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
                    overflow: Overflow.visible,
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
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            if (!bookPageIsLocked.value){
                              setState(() {
                                widget.book.checkpoint.value = Duration(seconds: ((details.globalPosition.dx / MediaQuery.of(context).size.width) * widget.book.length.inSeconds).round());
                              });
                              if (AudioService.running) {
                                AudioService.seekTo(widget.book.checkpoint.value).whenComplete(() => setState(() {}));
                              }
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
                    valueListenable: bookPageIsLocked,
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
                                    ? _timelineControlButton(
                                    Icons.skip_previous_outlined, () {
                                  setState(() {
                                    nextPreviousChapter(widget.book);
                                  });
                                })
                                    : Container(),
                                !value
                                    ? _timelineControlButton(
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
                                      return _timelineControlButton(icon, () {
                                        playBook(widget.book);
                                      });
                                    })
                                    : Container(),
                                !value
                                    ? _timelineControlButton(
                                    Icons.fast_forward_outlined, () {
                                  setState(() {
                                    forwardRewind(widget.book, forward: true);
                                  });
                                })
                                    : Container(),
                                !value
                                    ? _timelineControlButton(
                                    Icons.skip_next_outlined, () {
                                  setState(() {
                                    nextPreviousChapter(widget.book, next: true);
                                  });
                                })
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
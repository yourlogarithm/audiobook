import 'dart:async';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:audiobook/classes/book.dart';
import 'package:audiobook/classes/settings.dart';
import 'package:audiobook/pages/BookPage.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

backgroundTaskEntrypoint() {
  AudioServiceBackground.run(() => MyAudioPlayerTask());
}

class AudioController {

  static BookProvider? _currentBookProvider;

  static ValueNotifier<bool> sleep = ValueNotifier(false);
  static Timer? sleepTimer;
  static Timer? forceStopTimer;

  static StreamSubscription<Duration>? position;

  static void streamPosition() {
    position = AudioService.createPositionStream(steps: 1, minPeriod: Duration(milliseconds: 1000), maxPeriod: Duration(milliseconds: 1000)).listen((event) {});
    position!.onData((data) {
      if (data > _currentBookProvider!.currentBook.length) {
        _currentBookProvider!.currentBook.setCheckpoint(_currentBookProvider!.currentBook.length);
        AudioService.stop();
      }
      if (data.inSeconds != 0){
        _currentBookProvider!.currentBook.setCheckpoint(data);
      }
    });
  }

  static Future<void> _start(BookProvider bookProvider) async {
    _currentBookProvider = bookProvider;
    Settings.lastListenedBook.value = bookProvider.id;
    Settings.write();
    await AudioService.start(
        backgroundTaskEntrypoint: backgroundTaskEntrypoint,
        params: bookProvider.toAudioTaskMap(),
        rewindInterval: Settings.rewind,
        fastForwardInterval: Settings.forceStop
    );
    if (bookProvider.status == 'new' || bookProvider.status == 'read') {
      bookProvider.changeStatus('reading');
    }
    if (bookProvider.currentBook.checkpoint.value != bookProvider.currentBook.length) {
      await AudioService.seekTo(bookProvider.currentBook.checkpoint.value);
    } else {
      if (bookProvider.isBundle && bookProvider.currentBook != bookProvider.elements.last) {
        bookProvider.changeIndex(bookProvider.bookIndex+1);
        await AudioService.seekTo(bookProvider.currentBook.checkpoint.value);
      } else {
        await AudioService.seekTo(Duration(seconds: 0));
      }
    }
    if (position == null) {
      streamPosition();
    }
  }

  static Future<void> playPause(BookProvider bookProvider) async {
    if (AudioService.running){
      if(AudioService.playbackState.playing && AudioController._currentBookProvider?.currentBook.path == bookProvider.currentBook.path){
        AudioService.pause();
      } else {
        if (AudioController._currentBookProvider?.currentBook.path != bookProvider.currentBook.path) {
          await AudioService.stop();
          await _start(bookProvider);
        } else {
          AudioService.play();
        }
      }
    } else {
      await _start(bookProvider);
    }
  }

  static Future<void> seekTo(BookProvider bookProvider, Duration position) async {
    bookProvider.currentBook.setCheckpoint(position);
    print(position);
    if (AudioService.running) {
      AudioService.seekTo(position);
    }
  }

  static Future<void> forwardRewind(BookProvider bookProvider, {bool isRewind = false}) async {
    if (isRewind) {
      if (AudioService.running) {
        await AudioService.rewind();
      } else {
        bookProvider.currentBook.setCheckpoint(bookProvider.currentBook.checkpoint.value - Settings.rewind);
      }
    } else {
      if (AudioService.running) {
        await AudioService.fastForward();
      } else {
        bookProvider.currentBook.setCheckpoint(bookProvider.currentBook.checkpoint.value + Settings.rewind);
      }
    }
  }

  static Future<void> nextPrevious(BookProvider bookProvider, {bool isPrevious = false}) async {
    Chapter? currentChapter = bookProvider.currentBook.currentChapter;
    List<Chapter> chapters = bookProvider.currentBook.chapters;
    if (isPrevious) {
      if (chapters.isNotEmpty) {
        if (chapters.indexOf(currentChapter!) != 0) {
          Duration previousChapterStart = chapters[chapters.indexOf(currentChapter)-1].start;
          seekTo(bookProvider, previousChapterStart);
        } else {
          seekTo(bookProvider, currentChapter.start);
        }
      } else {
        seekTo(bookProvider, Duration.zero);
      }
    } else {
      if (chapters.isNotEmpty) {
        if (chapters.indexOf(currentChapter!) != chapters.length - 1) {
          Duration nextChapterStart = chapters[chapters.indexOf(currentChapter)+1].start + Duration(seconds: 1);
          seekTo(bookProvider, nextChapterStart);
        } else {
          seekTo(bookProvider, currentChapter.end);
        }
      } else {
        seekTo(bookProvider, bookProvider.currentBook.length);
      }
    }
  }
}

class MyAudioPlayerTask extends BackgroundAudioTask {
  static AudioPlayer player = AudioPlayer();

  @override
  Future<void> onStart(Map<String, dynamic>? params) async {
    if (AudioController.forceStopTimer != null){
      AudioController.forceStopTimer!.cancel();
    }
    AudioServiceBackground.setState(
        controls: [MediaControl.rewind, MediaControl.pause, MediaControl.fastForward],
        playing: true,
        processingState: AudioProcessingState.connecting
    );
    if (!params!['isBundle']){
      await player.setUrl(params['elements'][0]['path']);
      MediaItem item = MediaItem(
          id: params['elements'][0]['path'],
          title: params['elements'][0]['title'],
          album: params['elements'][0]['author'],
          artUri: Uri.file(params['cover'])
      );
      await AudioServiceBackground.setMediaItem(item);
    }
    player.play();
    AudioServiceBackground.setState(
        controls: [MediaControl.rewind, MediaControl.pause, MediaControl.fastForward],
        playing: true,
        processingState: AudioProcessingState.ready
    );
    AudioController.forceStopTimer = Timer(fastForwardInterval, () {
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
    if (AudioController.forceStopTimer != null) {
      AudioController.forceStopTimer!.cancel();
    }
    player.play();
    AudioServiceBackground.setState(
        controls: [MediaControl.rewind, MediaControl.pause, MediaControl.fastForward],
        playing: true,
        processingState: AudioProcessingState.ready
    );
    AudioController.forceStopTimer = Timer(fastForwardInterval, () {
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
    player.seek(position);
    AudioServiceBackground.setState(position: position);
  }

  @override
  Future<void> onRewind() async {
    Duration _position = player.position - rewindInterval;
    player.seek(_position);
    AudioServiceBackground.setState(position: _position);
  }

  @override
  Future<void> onFastForward() async {
    Duration _position = player.position + rewindInterval;
    player.seek(_position);
    AudioServiceBackground.setState(position: _position);
  }

  @override
  Future<void> onAddQueueItem(MediaItem mediaItem) {
    return super.onAddQueueItem(mediaItem);
  }
}

Widget _timelineControlButton(BuildContext context, IconData icon, Function function) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      customBorder: CircleBorder(),
      onTap: () {
        if (bookPageContextMenu.value.runtimeType == ContextMenu) {
          bookPageContextMenu.value = Container();
        }
        function();
      },
      child: Icon(icon, color: Settings.colors[3], size: MediaQuery.of(context).size.height * 0.06),
    ),
  );
}

class AudioProgressBar extends StatefulWidget {
  final BookProvider bookProvider;
  final bool isBookPage;
  const AudioProgressBar({required this.bookProvider, this.isBookPage = false});

  @override
  _AudioProgressBarState createState() => _AudioProgressBarState();
}

class _AudioProgressBarState extends State<AudioProgressBar> {

  late double buttonsTopPadding;
  late double buttonsHeight;
  double buttonsOpacity = 1;

  @override
  void initState() {
    buttonsTopPadding = 0.005;
    buttonsHeight = 0.075;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double _width = widget.isBookPage ? MediaQuery.of(context).size.width * 0.8 : MediaQuery.of(context).size.width * 0.9;
    return ValueListenableBuilder<Duration>(
      valueListenable: widget.bookProvider.currentBook.checkpoint,
      builder: ((context, value, _) {
        Duration _position = value;
        return SizedBox(
          width: _width,
          child: Column(
              children: [
                if (widget.isBookPage)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          convertDuration(_position),
                          style: TextStyle(color: Settings.colors[4], fontFamily: 'Poppins'),
                        ),
                        Text(
                          convertDuration(widget.bookProvider.currentBook.length),
                          style: TextStyle(
                              color: Settings.colors[4], fontFamily: 'Poppins'
                          ),
                        )
                      ],
                    ),
                  ),
                ValueListenableBuilder<bool>(
                    valueListenable: bookPageIsLocked,
                    builder: (context, value, _) {
                      bool isDraggable;
                      if (widget.bookProvider == BookProvider.nullBookProvider) {
                        isDraggable = false;
                      } else {
                        if (widget.isBookPage) {
                          isDraggable = value ? false : true;
                        } else {
                          isDraggable = false;
                        }
                      }
                      return SizedBox(
                          height: MediaQuery.of(context).size.height * (widget.isBookPage ? 0.025 : 0.02),
                          child: ProgressBar(
                            progress: _position,
                            total: widget.bookProvider.currentBook.length,
                            isDraggable: isDraggable,
                            thumbValue: (_position.inSeconds * 100 / widget.bookProvider.currentBook.length.inSeconds) / 100,
                            barHeight: 2.5,
                            timeLabelLocation: TimeLabelLocation.none,
                            progressBarColor: Settings.colors[6],
                            baseBarColor: Settings.colors[5],
                            thumbColor: Settings.colors[6],
                            thumbGlowColor: Settings.colors[6].withOpacity(0.3),
                            thumbGlowRadius: MediaQuery.of(context).size.height * 0.0125,
                            thumbRadius: MediaQuery.of(context).size.height * 0.01,
                            onSeek: (position) {
                              AudioController.seekTo(widget.bookProvider, position);
                              },
                          )
                        );
                    }
                ),
                ValueListenableBuilder<bool>(
                    valueListenable: bookPageIsLocked,
                    builder: (context, value, _) {
                      if (widget.isBookPage){
                        if (value) {
                          buttonsTopPadding = 0;
                          buttonsHeight = 0;
                          buttonsOpacity = 0;
                        } else {
                          buttonsTopPadding = 0.005;
                          buttonsHeight = 0.075;
                          buttonsOpacity = 1;
                        }
                      }
                      return AnimatedContainer(
                        duration: bookPageIsLocked.value ? Duration(milliseconds: 500) : Duration(milliseconds: 250),
                        height: MediaQuery.of(context).size.height * buttonsHeight,
                        padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * buttonsTopPadding),
                        width: _width,
                        child: AnimatedOpacity(
                          opacity: buttonsOpacity,
                          duration: bookPageIsLocked.value ? Duration(milliseconds: 250) : Duration(milliseconds: 500),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _timelineControlButton(context, Icons.skip_previous_outlined, () {
                                  setState(() {
                                    AudioController.nextPrevious(widget.bookProvider, isPrevious: true);
                                  });
                                }),
                                _timelineControlButton(context, Icons.fast_rewind_outlined, () {
                                  if (widget.bookProvider.id != -1) {
                                    setState(() {
                                      AudioController.forwardRewind(widget.bookProvider, isRewind: true);
                                    });
                                  }
                                }),
                                widget.bookProvider.id != -1 ? StreamBuilder<PlaybackState>(
                                    stream: AudioService.playbackStateStream,
                                    builder: (context, snapshot) {
                                      IconData icon = Icons.play_arrow;
                                      if (snapshot.hasData) {
                                        if (snapshot.data!.playing && AudioController._currentBookProvider?.currentBook.path == widget.bookProvider.currentBook.path) {
                                          icon = Icons.pause;
                                        }
                                      }
                                      return _timelineControlButton(context, icon, () {
                                        AudioController.playPause(widget.bookProvider);
                                      });
                                    }
                                ) : _timelineControlButton(
                                    context, Icons.play_arrow, () {}
                                ),
                                _timelineControlButton(
                                    context, Icons.fast_forward_outlined, () async {
                                  if (widget.bookProvider.id != -1) {
                                    setState((){
                                      if (AudioService.running) {
                                        AudioController.forwardRewind(widget.bookProvider);
                                      } else {
                                        widget.bookProvider.currentBook.setCheckpoint(widget.bookProvider.currentBook.checkpoint.value+Settings.rewind);
                                        if (widget.bookProvider.currentBook.checkpoint.value > widget.bookProvider.currentBook.length) {
                                          widget.bookProvider.currentBook.setCheckpoint(widget.bookProvider.currentBook.length);
                                        }
                                      }
                                    });
                                  }
                                }),
                                _timelineControlButton(context, Icons.skip_next_outlined, () {
                                  setState(() {
                                    AudioController.nextPrevious(widget.bookProvider);
                                  });
                                })
                              ]
                          )
                        )
                      );
                    }
                )
              ]),
        );
        })
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
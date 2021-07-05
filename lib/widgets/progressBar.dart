import 'package:audio_service/audio_service.dart';
import 'package:audiobook/classes/audio_video_progress_bar.dart';
import 'package:audiobook/classes/audioController.dart';
import 'package:audiobook/classes/book.dart';
import 'package:audiobook/classes/player.dart';
import 'package:audiobook/classes/settings.dart';
import 'package:audiobook/pages/BookPage.dart';
import 'package:flutter/material.dart';

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
                                AudioController.seek(position, widget.bookProvider);
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
                                          AudioController.skipTo(widget.bookProvider, isPrevious: true);
                                        });
                                      }),
                                      _timelineControlButton(context, Icons.fast_rewind_outlined, () {
                                        if (widget.bookProvider.id != -1) {
                                          setState(() {
                                            AudioController.rewind(widget.bookProvider);
                                          });
                                        }
                                      }),
                                      widget.bookProvider.id != -1 ? StreamBuilder<PlaybackState>(
                                          stream: AudioService.playbackStateStream,
                                          builder: (context, snapshot) {
                                            IconData icon = Icons.play_arrow;
                                            if (snapshot.hasData) {
                                              if (snapshot.data!.playing && widget.bookProvider.id == AudioService.currentMediaItem?.extras!['id']) {
                                                icon = Icons.pause;
                                              }
                                            }
                                            return _timelineControlButton(context, icon, () {
                                              AudioController.play(widget.bookProvider);
                                            });
                                          }
                                      ) : _timelineControlButton(context, Icons.play_arrow, () {}
                                      ),
                                      _timelineControlButton(
                                          context, Icons.fast_forward_outlined, () async {
                                        if (widget.bookProvider.id != -1) {
                                          setState((){
                                            AudioController.forward(widget.bookProvider);
                                          });
                                        }
                                      }),
                                      _timelineControlButton(context, Icons.skip_next_outlined, () {
                                        setState(() {
                                          AudioController.skipTo(widget.bookProvider, isPrevious: false);
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
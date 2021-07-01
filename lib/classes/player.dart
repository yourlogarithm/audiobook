import 'dart:async';
import 'package:audiobook/classes/book.dart';
import 'package:audiobook/classes/settings.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

_backgroundTaskEntrypoint() {
  AudioServiceBackground.run(() => MyAudioPlayerTask());
}

List<MediaItem> _mediaItems = [];
int _bookIndex = 0;

class AudioController {

  static BookProvider? currentBookProvider;

  static ValueNotifier<bool> sleep = ValueNotifier(false);
  static Timer? sleepTimer;
  static Timer? forceStopTimer;

  static StreamSubscription<Duration>? position;
  static StreamSubscription<List<MediaItem>>? queue;

  static void streamPosition() {
    position = AudioService.createPositionStream(steps: 1, minPeriod: Duration(milliseconds: 1000), maxPeriod: Duration(milliseconds: 1000)).listen((event) {});
    position!.onData((data) {
      if (data >= Duration.zero && data < currentBookProvider!.currentBook.length && AudioService.playbackState.playing) {
        currentBookProvider!.currentBook.setCheckpoint(data);
      }
    });
  }

  static Future<void> _start(BookProvider bookProvider) async {
    currentBookProvider = bookProvider;
    Settings.lastListenedBook.value = bookProvider.id;
    Settings.write();
    await AudioService.start(
        backgroundTaskEntrypoint: _backgroundTaskEntrypoint,
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
        bookProvider.changeIndex(bookProvider.bookIndex.value+1);
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
      if(AudioService.playbackState.playing && AudioController.currentBookProvider?.currentBook.path == bookProvider.currentBook.path){
        AudioService.pause();
      } else {
        if (AudioController.currentBookProvider?.currentBook.path != bookProvider.currentBook.path) {
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
    if (AudioService.running) {
      AudioService.seekTo(position);
    }
  }

  static Future<void> forwardRewind(BookProvider bookProvider, {bool isRewind = false}) async {
    if (isRewind) {
      if (AudioService.running) {
        await AudioService.rewind();
      } else {
        Duration _position = bookProvider.currentBook.checkpoint.value - Settings.rewind;
        if (_position < Duration.zero){
          _position = Duration.zero;
        }
        bookProvider.currentBook.setCheckpoint(_position);
      }
    } else {
      if (AudioService.running) {
        await AudioService.fastForward();
      } else {
        Duration _position = bookProvider.currentBook.checkpoint.value + Settings.rewind;
        if (_position > bookProvider.currentBook.length){
          _position = bookProvider.currentBook.length;
        }
        bookProvider.currentBook.setCheckpoint(_position);
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
  static ConcatenatingAudioSource? _playlist;
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
    } else {
      List<AudioSource> audioSources = [];
      _bookIndex = params['bookIndex'];
      for (int i = 0; i < params['elements'].length; i++){
        audioSources.add(AudioSource.uri(Uri.file(params['elements'][i]['path']), tag: params['elements'][i]['title']));
        _mediaItems.add(
            MediaItem(
              id: params['elements'][i]['path'],
              title: params['elements'][i]['title'],
              album: params['elements'][i]['author'],
              artUri: Uri.file(params['hasCover'] ? params['cover'] : params['elements'][i]['cover'])
            )
        );
      }
      _playlist = ConcatenatingAudioSource(children: audioSources);
      await player.setAudioSource(_playlist!);
      await AudioServiceBackground.setQueue(_mediaItems);
      await AudioServiceBackground.setMediaItem(_mediaItems[_bookIndex]);
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
    if (_position < Duration.zero) {
      _position = Duration.zero;
    }
    player.seek(_position);
    AudioServiceBackground.setState(position: _position);
  }

  @override
  Future<void> onFastForward() async {
    Duration _position = player.position + rewindInterval;
    if (_position > player.duration!){
      _position = player.duration!;
    }
    player.seek(_position);
    AudioServiceBackground.setState(position: _position);
  }

  @override
  Future<void> onSkipToNext() async {
    await Future.wait([
      AudioServiceBackground.setMediaItem(_mediaItems[_bookIndex]),
      AudioServiceBackground.setState(position: Duration.zero)
    ]);
    return super.onSkipToNext();
  }
}
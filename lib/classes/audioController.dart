import 'dart:async';
import 'package:audiodept/classes/book.dart';
import 'package:audiodept/classes/player.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audiodept/classes/settings.dart';
import 'package:flutter/cupertino.dart';

backgroundTaskEntrypoint() {
  AudioServiceBackground.run(() => MyAudioPlayerTask());
}

class AudioController {

  static ValueNotifier<bool> isSetSleepTimer = ValueNotifier(false);
  static Timer? sleepTimer;
  static StreamSubscription<Duration>? positionSubscription;

  static bool skipping = false;

  static void initSleep() {
    isSetSleepTimer.value = true;
    sleepTimer = Timer(Settings.sleep, () {
      if (AudioService.running){
        AudioService.stop();
      }
      isSetSleepTimer.value = false;
    });
  }

  static void cancelSleep() {
    isSetSleepTimer.value = false;
    sleepTimer?.cancel();
  }

  static void sleep() {
    if (isSetSleepTimer.value && sleepTimer != null){
      cancelSleep();
    } else {
      initSleep();
    }
  }

  static void startListening(int id) async {
    positionSubscription = AudioService.positionStream.listen((event) {
      print(event);
    });
    positionSubscription!.onData((data) async {
      BookProvider bookProvider = allBooks.firstWhere((element) => element.id == id);
      if (AudioService.running && data != bookProvider.currentBook.length) {
        if (data < bookProvider.currentBook.length){
          bookProvider.currentBook.setCheckpoint(data);
        } else if (!skipping) {
          AudioController.next(bookProvider);
        }
      }
    });
  }

  static void cancelListening() {
    positionSubscription?.cancel();
  }

  static Future<void> start(BookProvider bookProvider) async {
    cancelListening();
    startListening(bookProvider.toAudioTaskMap()['id']);
    if (bookProvider.status != 'reading'){
      bookProvider.changeStatus('reading');
    }
    await AudioService.start(
      backgroundTaskEntrypoint: backgroundTaskEntrypoint,
      params: bookProvider.toAudioTaskMap(),
      rewindInterval: Settings.rewind,
      fastForwardInterval: Settings.forceStop,
      androidNotificationIcon: 'mipmap/launcher_icon'
    );
    Settings.lastListenedBook.value = bookProvider.id;
    Settings.write();
  }

  static void play(BookProvider bookProvider) async {
    if (AudioService.running){
      if (bookProvider.id == AudioService.currentMediaItem?.extras!['id']){
        if (AudioService.playbackState.playing) {
          AudioService.pause();
        } else {
          AudioService.play();
        }
      } else {
        await AudioService.stop();
        await start(bookProvider);
      }
    } else {
      await start(bookProvider);
    }
  }
  
  static void rewind(BookProvider bookProvider) {
    if (AudioService.running) {
      AudioService.rewind();
    } else {
      Duration _position = bookProvider.currentBook.checkpoint.value - Settings.rewind;
      _position = _position < Duration.zero ? Duration.zero : _position;
      bookProvider.currentBook.setCheckpoint(_position);
    }
  }

  static void forward(BookProvider bookProvider){
    if (AudioService.running) {
      AudioService.fastForward();
    } else {
      Duration _position = bookProvider.currentBook.checkpoint.value + Settings.rewind;
      _position = _position > bookProvider.currentBook.length ? bookProvider.currentBook.length : _position;
      bookProvider.currentBook.setCheckpoint(bookProvider.currentBook.checkpoint.value + Settings.rewind);
    }
  }

  static void seek(Duration position, BookProvider bookProvider) {
    if (AudioService.running) {
      AudioService.seekTo(position);
    } else {
      bookProvider.currentBook.setCheckpoint(position);
    }
  }

  static void skipTo(BookProvider bookProvider, {required bool isPrevious}) {
    if (bookProvider.currentBook.chapters.isNotEmpty){
      Duration position;
      int index = bookProvider.currentBook.chapters.indexOf(bookProvider.currentBook.currentChapter);
      if ((index > 0 && isPrevious) || (index < bookProvider.currentBook.chapters.length-1 && !isPrevious)){
        position = isPrevious ? bookProvider.currentBook.previousChapter.start : bookProvider.currentBook.nextChapter.start + Duration(seconds: 1);
        if (AudioService.running){
          AudioService.seekTo(position);
        } else {
          bookProvider.currentBook.setCheckpoint(position);
        }
      } else {
        isPrevious ? previous(bookProvider) : next(bookProvider);
      }
    } else {
      isPrevious ? previous(bookProvider) : next(bookProvider);
    }
  }

  static void previous(BookProvider bookProvider) async {
    if (bookProvider.isBundle){
      if (bookProvider.bookIndex.value > 0) {
        bookProvider.changeIndex(bookProvider.bookIndex.value-1);
        bookProvider.currentBook.setCheckpoint(Duration.zero);
        if (AudioService.running) {
          await AudioService.skipToPrevious();
        }
      }
    } else {
      bookProvider.currentBook.setCheckpoint(Duration.zero);
    }
  }

  static void next(BookProvider bookProvider) async {
    skipping = true;
    if (bookProvider.isBundle){
      if (bookProvider.bookIndex.value < bookProvider.elements.length - 1){
        bookProvider.changeIndex(bookProvider.bookIndex.value+1);
        bookProvider.currentBook.setCheckpoint(Duration.zero);
        if (AudioService.running) {
          await AudioService.skipToNext();
        }
      } else {
        if (AudioService.running) {
          await AudioService.stop();
          bookProvider.changeStatus('read');
        }
        bookProvider.currentBook.setCheckpoint(bookProvider.currentBook.length);
      }
    } else{
      if (AudioService.running){
        await AudioService.stop();
        bookProvider.changeStatus('read');
      }
      bookProvider.currentBook.setCheckpoint(bookProvider.currentBook.length);
    }
  skipping = false;
  }
}
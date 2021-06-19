import 'dart:async';
import 'package:audiobook/classes/book.dart';
import 'package:audiobook/classes/settings.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

String playerUrl = '';

ValueNotifier<bool> sleep = ValueNotifier(false);
late Timer sleepTimer;

backgroundTaskEntrypoint() {
  AudioServiceBackground.run(() => MyAudioPlayerTask());
}

void playBook(Book book) async {
  if (AudioService.running) {
    if (AudioService.playbackState.playing && playerUrl == book.path) {
      AudioService.pause();
    } else {
      if (playerUrl == book.path) {
        AudioService.play();
      } else {
        playerUrl = book.path;
        await AudioService.stop();
        await AudioService.start(backgroundTaskEntrypoint: backgroundTaskEntrypoint, params: book.toMap());
        if (book.checkpoint != book.length) {
          await AudioService.seekTo(book.checkpoint);
        } else {
          await AudioService.seekTo(Duration(seconds: 0));
        }
      }
    }
  } else {
    playerUrl = book.path;
    await AudioService.start(backgroundTaskEntrypoint: backgroundTaskEntrypoint, params: book.toMap());
    if (book.checkpoint != book.length) {
      await AudioService.seekTo(book.checkpoint);
    } else {
      await AudioService.seekTo(Duration(seconds: 0));
    }
  }
}
void forwardRewind(Book book, {bool forward = false}){
  Duration edited = forward ? book.checkpoint+Settings.rewind : book.checkpoint-Settings.rewind;
  if (edited < Duration(seconds: 0)) {
    edited = Duration(seconds: 0);
  } else if (edited > book.length){
    edited = book.length;
  }
  book.checkpoint = edited;
  if (AudioService.running){
    AudioService.seekTo(edited);
  }
  book.update();
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
    player.play();
    AudioServiceBackground.setState(
        controls: [MediaControl.rewind, MediaControl.pause, MediaControl.fastForward],
        playing: true,
        processingState: AudioProcessingState.ready
    );
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
    return super.onRewind();
  }

  @override
  Future<void> onFastForward() async {
    return super.onFastForward();
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
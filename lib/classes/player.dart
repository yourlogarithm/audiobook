import 'dart:async';
import 'package:audiobook/classes/audioController.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

class MyAudioPlayerTask extends BackgroundAudioTask {
  static AudioPlayer player = AudioPlayer();
  static Timer? forceStopTimer;
  static Timer? sleepTimer;
  static ValueNotifier<bool> isSleepTimer = ValueNotifier(false);
  static List<MediaItem>? _mediaItems;
  static int _bookIndex = 0;

  @override
  Future<void> onStart(Map<String, dynamic>? params) async {
    _bookIndex = params!['bookIndex'];
    _mediaItems?.clear();
    _mediaItems = List.generate(params['elements'].length, (i) {
      return MediaItem(
        id: params['elements'][i]['path'],
        title: params['title'],
        album: params['author'],
        artUri: Uri.file(params['cover'] != null ? params['cover'] : params['elements'][i]['cover']),
        extras: {'id': params['id']}
      );
    });
    await Future.wait([
      AudioServiceBackground.setMediaItem(_mediaItems![params['bookIndex']]),
      AudioServiceBackground.setState(
          controls: [MediaControl.rewind, MediaControl.pause, MediaControl.fastForward],
          playing: true,
          processingState: AudioProcessingState.connecting
      ),
      player.setUrl(_mediaItems![params['bookIndex']].id).whenComplete(() async {
        player.play();
      }),
    ]);
    AudioService.seekTo(Duration(seconds: params['elements'][params['bookIndex']]['checkpoint'])).whenComplete(() {
      AudioServiceBackground.setState(
        controls: [MediaControl.rewind, MediaControl.pause, MediaControl.fastForward],
        playing: true,
        processingState: AudioProcessingState.ready
      );
    });
    if (forceStopTimer != null){
      forceStopTimer!.cancel();
    }
    forceStopTimer = Timer(fastForwardInterval, () {
      if (AudioService.playbackState.playing) {
        AudioService.pause();
      }
    });
    return super.onStart(params);
  }

  @override
  Future<void> onStop() async {
    AudioController.cancelListening();
    await Future.wait([
      AudioServiceBackground.setState(
          controls: [],
          playing: false,
          processingState: AudioProcessingState.stopped
      ),
      player.stop()
    ]);
    if (forceStopTimer != null) {
      forceStopTimer!.cancel();
    }
    return super.onStop();
  }

  @override
  Future<void> onPlay() async {
    player.play();
    AudioServiceBackground.setState(
    controls: [MediaControl.rewind, MediaControl.pause, MediaControl.fastForward],
    playing: true,
    processingState: AudioProcessingState.ready
    );
    if (forceStopTimer != null) {
      forceStopTimer!.cancel();
    }
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
    player.seek(position);
    AudioServiceBackground.setState(position: position);
  }

  @override
  Future<void> onRewind() async {
    Duration _position = player.position - rewindInterval;
    if (_position < Duration.zero) {
      _position = Duration.zero;
    }
    await Future.wait([
      player.seek(_position),
      AudioServiceBackground.setState(position: _position)
    ]);
  }

  @override
  Future<void> onFastForward() async {
    Duration _position = player.position + rewindInterval;
    if (_position > player.duration!){
      _position = player.duration!;
    }
    await Future.wait([
      player.seek(_position),
      AudioServiceBackground.setState(position: _position)
    ]);
  }

  @override
  Future<void> onSkipToPrevious() async {
    await AudioServiceBackground.setState(position: Duration.zero);
    _bookIndex--;
    await Future.wait([
      AudioServiceBackground.setMediaItem(_mediaItems![_bookIndex]),
      player.setUrl(_mediaItems![_bookIndex].id)
    ]);
    return super.onSkipToPrevious();
  }

  @override
  Future<void> onSkipToNext() async {
    await AudioServiceBackground.setState(position: Duration.zero);
    _bookIndex++;
    await Future.wait([
      AudioServiceBackground.setMediaItem(_mediaItems![_bookIndex]),
      player.setUrl(_mediaItems![_bookIndex].id),
    ]);
    return super.onSkipToNext();
  }

  @override
  Future onCustomAction(String name, arguments) {
    switch (name) {
      case 'activateSleepTimer':
        sleepTimer?.cancel();
        sleepTimer = Timer(arguments, () {
          if (AudioService.playbackState.playing) {
            AudioService.pause();
          }
        });
        isSleepTimer.value = true;
        break;
      case 'deactivateSleepTimer':
        sleepTimer?.cancel();
        isSleepTimer.value = false;
        break;
    }
    return super.onCustomAction(name, arguments);
  }
}
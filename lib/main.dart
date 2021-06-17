import 'package:audio_service/audio_service.dart';
import 'package:audiobook/content.dart';
import 'package:audiobook/loading.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    initialRoute: '/loading',
    routes: {
      '/loading': (context) => Loading(),
      '/content': (context) => AudioServiceWidget(child: Content())
    },
  ));
}

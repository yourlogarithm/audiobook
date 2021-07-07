import 'package:audio_service/audio_service.dart';
import 'package:audiodept/content.dart';
import 'package:audiodept/loading.dart';
import 'package:flutter/material.dart';

GlobalKey<NavigatorState> mainNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
      navigatorKey: mainNavigatorKey,
      initialRoute: '/loading',
      routes: {
        '/loading': (context) => Loading(),
        '/content': (context) =>  AudioServiceWidget(child: Content())
      },
    )
  );
}

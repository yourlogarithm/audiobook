import 'package:audio_service/audio_service.dart';
import 'package:audiobook/classes/ad.dart';
import 'package:audiobook/content.dart';
import 'package:audiobook/loading.dart';
import 'package:flutter/material.dart';

GlobalKey<NavigatorState> mainNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
      navigatorKey: mainNavigatorKey,
      initialRoute: '/loading',
      routes: {
        '/loading': (context) => Loading(),
        '/content': (context) => AudioServiceWidget(child: Content())
      },
    )
  );
}

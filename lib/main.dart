import 'package:audio_service/audio_service.dart';
import 'package:audiobook/classes/ad.dart';
import 'package:audiobook/content.dart';
import 'package:audiobook/loading.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

GlobalKey<NavigatorState> mainNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final initFuture = MobileAds.instance.initialize();
  final adState = AdState(initFuture);
  runApp(MaterialApp(
      navigatorKey: mainNavigatorKey,
      initialRoute: '/loading',
      routes: {
        '/loading': (context) => Loading(),
        '/content': (context) => AudioServiceWidget(child: Provider.value(
            value: adState,
            builder: (context, child) => Content(),
        ))
      },
    )
  );
}

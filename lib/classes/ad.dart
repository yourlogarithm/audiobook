import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

late AnchoredAdaptiveBannerAdSize adaptiveBannerSize;

class AdWidgets {
  static Container? libraryPag;
  static Container? homePag;
  static Container? settingsPag;
}

void _setLoaded() {
  AdState.loaded = true;
}

class AdState {
  static bool loaded = false;
  late Future<InitializationStatus> initialization;
  AdState(this.initialization);
  String get bannerAdUnitId => 'ca-app-pub-3940256099942544/6300978111';
  BannerAdListener get adListener => _adListener;


  BannerAdListener _adListener = BannerAdListener(
    onAdLoaded: (ad) {
      _setLoaded();
    }
  );
}
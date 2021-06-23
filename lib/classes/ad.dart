import 'package:google_mobile_ads/google_mobile_ads.dart';

class MyNativeAd {
  final String nativeAdId = 'ca-app-pub-3940256099942544/2247696110';
  late NativeAd ad;
  MyNativeAd() {
    ad = NativeAd(
      adUnitId: nativeAdId,

    );
  }
}
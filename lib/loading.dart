import 'package:audiobook/classes/ad.dart';
import 'package:audiobook/classes/book.dart';
import 'package:audiobook/classes/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'classes/settings.dart';

class Loading extends StatelessWidget {
  // const Loading({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AdSize.getAnchoredAdaptiveBannerAdSize(Orientation.portrait, MediaQuery.of(context).size.width.toInt()).then((value) => adaptiveBannerSize = value!);
    DatabaseProvider.getBooks().then((value) {
      books = value;
      Settings.init().whenComplete(() {
        Navigator.pushReplacementNamed(context, '/content');
      });
    });
    return Scaffold(
      backgroundColor: Color(0xff2E3247),
      body: Center(
        child: SpinKitRing(color: Color(0xffE42861)),
      ),
    );
  }
}

import 'dart:async';
import 'package:audiodept/classes/book.dart';
import 'package:audiodept/classes/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'classes/settings.dart';

class Loading extends StatefulWidget {
  final bool isFirst;
  const Loading({this.isFirst = true});

  @override
  _LoadingState createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {

  Future<void> load() async {
    Settings.init().whenComplete(() async {
      await DatabaseProvider.getBookProviders.then((value) => allBooks = value);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/content');
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    if (widget.isFirst){
      load();
    }
    return Scaffold(
      backgroundColor: Color(0xff2E3247),
      body: Center(
        child: SpinKitRing(color: Color(0xffE42861)),
      ),
    );
  }
}

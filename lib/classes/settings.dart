import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

class Settings {
  static late File jsonFile;
  static late Directory dir;
  static late String fileName;
  static late bool fileExists = false;
  static late Map<String, dynamic> fileContent;

  static late Duration sleep;
  static late ValueNotifier<String> theme = ValueNotifier('Dark');
  static late Duration rewind;
  static late Duration forceStop;
  static late String defaultFolder;
  static late List<Color> colors;
  static late String selectedBookPath;
  static late File defaultImage;
  static late ValueNotifier<int> lastListenedBook;

  static String get defaultCover => '${dir.path}/defaultCover.png';

  static Future<void> init() async {
    dir = await getApplicationDocumentsDirectory();
    jsonFile = File(dir.path + '/' + 'settings.json');
    fileExists = await jsonFile.exists();
    if (fileExists) {
      String data = await jsonFile.readAsString();
      fileContent = jsonDecode(data);
      sleep = Duration(minutes: fileContent['sleep']);
      theme.value = fileContent['theme'];
      rewind = Duration(seconds: fileContent['rewind']);
      forceStop = Duration(hours: fileContent['forceStop']);
      defaultFolder = fileContent['defaultFolder'];
      selectedBookPath = fileContent['selectedBookPath'];
      lastListenedBook = ValueNotifier(fileContent['lastListenedBook']);
      setColors(theme.value);
    } else {
      await createFile();
    }
  }

  static Future<void> createFile() async {
    File file = File(dir.path + '/' + 'settings.json');
    sleep = Duration(minutes: 10);
    theme.value = 'Dark';
    rewind = Duration(seconds: 15);
    forceStop = Duration(hours: 2);
    defaultFolder = '/storage/emulated/0';
    selectedBookPath = '';
    lastListenedBook = ValueNotifier(-1);
    defaultImage = File(dir.path + '/' + 'defaultCover.png');
    defaultImage.create(recursive: true);
    ByteData defaultImageData = await rootBundle.load('images/defaultcover.png');
    List<int> bytes = defaultImageData.buffer.asUint8List(defaultImageData.offsetInBytes, defaultImageData.lengthInBytes);
    defaultImage.writeAsBytes(bytes);
    setColors(theme.value);
    fileContent = toMap();
    file.create().whenComplete(() {
      fileExists = true;
      file.writeAsString(jsonEncode(fileContent));
    });
  }

  static void write() {
    fileContent = toMap();
    jsonFile.writeAsString(jsonEncode(fileContent));
  }

  static Map<String, dynamic> toMap() {
    return {
      'sleep': sleep.inMinutes,
      'theme': theme.value,
      'rewind': rewind.inSeconds,
      'forceStop': forceStop.inHours,
      'defaultFolder': defaultFolder,
      'selectedBookPath': selectedBookPath,
      'lastListenedBook': lastListenedBook.value
    };
  }

  static void setColors(String theme) {
    colors = [];
    switch (theme) {
      case 'Dark':
        colors = [
          Color(0xff363B54),
          Color(0xff2E3247),
          Color(0xff212433),
          Colors.white,
          Color(0xff696A91),
          Color(0xffFF3D78),
          Color(0xffE42861),
          Color(0xffBDBEF1)
        ];
        break;
      case 'Light':
        colors = [
          Color(0xffffffff),
          Color(0xfff1f1f1),
          Color(0xffffffff),
          Color(0xff383838),
          Color(0xff727272),
          Color(0xffFF3D78),
          Color(0xffE42861),
          Color(0xffBDBEF1)
        ];
        break;
    }
  }
}
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/material.dart';

class FileExplorer {
  static final String rootPath = 'storage/emulated/0';
  ValueNotifier<String> path = ValueNotifier(rootPath);

  void navigateToDir(String pathParameter) {
    path.value = pathParameter;
  }

  Future<List<FileSystemEntity>> listDir(String arg) async {
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
      listDir(arg);
    }
    List<FileSystemEntity> dirs = await Directory(arg).list().toList();
    return dirs;
  }

  static List<String> audioFormats = [
    '.mp3',
    '.aax',
    '.m4a',
    '.m4b',
    '.aac',
    '.m4p',
    '.ogg',
    '.wma',
    '.flac',
    '.alac'
  ];
  static List<String> imageFormats = ['.png', '.jpg', '.jpeg'];
}
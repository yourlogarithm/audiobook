import 'package:audiobook/classes/explorer.dart';
import 'package:audiobook/classes/settings.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:numberpicker/numberpicker.dart';

class SettingsPage extends StatefulWidget {
  // const SettingsPage({Key key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Widget button(
      IconData icon, String text, Widget dialog, BuildContext context) {
    return Column(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.2,
          height: MediaQuery.of(context).size.width * 0.2,
          decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
            BoxShadow(
                color: Settings.colors[6].withOpacity(0.5),
                spreadRadius: 0.1,
                blurRadius: 10)
          ]),
          child: FloatingActionButton(
            heroTag: null,
            onPressed: () {
              showDialog(context: context, builder: (_) => dialog)
                  .whenComplete(() => setState(() {}));
            },
            elevation: 0,
            backgroundColor: Settings.colors[6],
            child: Icon(icon, color: Colors.white, size: 48),
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 10),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Settings.colors[3],
                height: 1,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                fontSize: 20),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
            padding: EdgeInsets.symmetric(horizontal: 25),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.1,
            color: Settings.theme.value == 'Dark'
                ? Settings.colors[2]
                : Settings.colors[1],
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        color: Settings.colors[3]),
                  ),
                ],
              ),
            )),
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.9,
          color: Settings.theme.value == 'Dark'
              ? Settings.colors[2]
              : Settings.colors[1],
          child: Container(
            decoration: BoxDecoration(
                color: Settings.colors[0],
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: Settings.theme.value == 'Dark'
                    ? [
                        BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.1),
                            offset: Offset(0, -3),
                            blurRadius: 5,
                            spreadRadius: 1)
                      ]
                    : [
                        BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.05),
                            blurRadius: 7,
                            spreadRadius: 0.1)
                      ]),
            child: Container(
              margin: EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      button(
                          Icons.timer, 'Sleep\ntimer', SleepTimer(), context),
                      button(Icons.brush_outlined, 'Theme', Theme(), context),
                      button(Icons.fast_rewind_outlined, 'Rewind', Rewind(),
                          context),
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        button(Icons.highlight_off, 'Force\nstop', ForceStop(),
                            context),
                        button(Icons.equalizer_rounded, 'Equalizer',
                            Equalizer(), context),
                        button(Icons.folder_open, 'Default\nfolder',
                            DefaultFolder(), context),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}

class SleepTimer extends StatefulWidget {
  // const SleepTimer({Key key}) : super(key: key);

  @override
  _SleepTimerState createState() => _SleepTimerState();
}

class _SleepTimerState extends State<SleepTimer> {
  int duration = Settings.sleep.inMinutes;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Settings.colors[0],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      actionsPadding: EdgeInsets.fromLTRB(0, 0, 20, 5),
      contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 12),
      title: Text(
        'Sleep Timer (minutes)',
        style: TextStyle(
            color: Settings.colors[3],
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600),
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.1,
        decoration: BoxDecoration(
            color: Settings.theme.value == 'Dark'
                ? Settings.colors[2]
                : Settings.colors[1],
            borderRadius: BorderRadius.circular(25)),
        child: Center(
          child: NumberPicker(
              onChanged: (value) => setState(() => duration = value),
              value: duration,
              itemWidth: 70,
              minValue: 2,
              maxValue: 120,
              axis: Axis.horizontal,
              textStyle: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  color: Settings.colors[3]),
              selectedTextStyle: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                  color: Settings.colors[6])),
        ),
      ),
      actions: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              'Cancel',
              style: TextStyle(
                  color: Settings.colors[6],
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
        InkWell(
          onTap: () {
            if (duration != Settings.sleep.inMinutes) {
              Settings.sleep = Duration(minutes: duration);
              Settings.write();
            }
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              'Confirm',
              style: TextStyle(
                  color: Settings.colors[6],
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600),
            ),
          ),
        )
      ],
    );
  }
}

class Theme extends StatefulWidget {
  // const Theme({Key key}) : super(key: key);

  @override
  _ThemeState createState() => _ThemeState();
}

class _ThemeState extends State<Theme> {
  List<bool> isSelected =
      Settings.theme.value == 'Dark' ? [false, true] : [true, false];

  List<String> options = ['Light', 'Dark'];
  String selected = Settings.theme.value;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Settings.colors[0],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      actionsPadding: EdgeInsets.fromLTRB(0, 0, 20, 5),
      contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 12),
      title: Text(
        'Theme',
        style: TextStyle(
            color: Settings.colors[3],
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600),
      ),
      content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.1,
          decoration: BoxDecoration(
              color: Settings.theme.value == 'Dark'
                  ? Settings.colors[2]
                  : Settings.colors[1],
              borderRadius: BorderRadius.circular(25)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ToggleButtons(
                onPressed: (int index) {
                  for (int i = 0; i < isSelected.length; i++) {
                    setState(() {
                      selected = options[index];
                      isSelected[i] = i == index ? true : false;
                    });
                  }
                },
                constraints: BoxConstraints(minWidth: constraints.maxWidth / 2),
                borderRadius: BorderRadius.circular(25),
                isSelected: isSelected,
                fillColor: Settings.colors[6],
                renderBorder: false,
                color: Settings.colors[3],
                selectedColor: Colors.white,
                children: [
                  Text('Light',
                      style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600)),
                  Text('Dark',
                      style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600))
                ],
              );
            },
          )),
      actions: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              'Cancel',
              style: TextStyle(
                  color: Settings.colors[6],
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
        InkWell(
          onTap: () {
            if (selected != Settings.theme.value) {
              Settings.theme.value = selected;
              Settings.setColors(selected);
              Settings.write();
            }
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              'Confirm',
              style: TextStyle(
                  color: Settings.colors[6],
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600),
            ),
          ),
        )
      ],
    );
  }
}

class Rewind extends StatefulWidget {
  // const Rewind({Key key}) : super(key: key);

  @override
  _RewindState createState() => _RewindState();
}

class _RewindState extends State<Rewind> {
  int duration = Settings.rewind.inSeconds;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Settings.colors[0],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      actionsPadding: EdgeInsets.fromLTRB(0, 0, 20, 5),
      contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 12),
      title: Text(
        'Rewind time (sec)',
        style: TextStyle(
            color: Settings.colors[3],
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600),
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.1,
        decoration: BoxDecoration(
            color: Settings.theme.value == 'Dark'
                ? Settings.colors[2]
                : Settings.colors[1],
            borderRadius: BorderRadius.circular(25)),
        child: Center(
          child: NumberPicker(
              onChanged: (value) => setState(() => duration = value),
              value: duration,
              itemWidth: 70,
              minValue: 5,
              maxValue: 60,
              axis: Axis.horizontal,
              textStyle: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  color: Settings.colors[3]),
              selectedTextStyle: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                  color: Settings.colors[6])),
        ),
      ),
      actions: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              'Cancel',
              style: TextStyle(
                  color: Settings.colors[6],
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
        InkWell(
          onTap: () {
            if (duration != Settings.rewind.inSeconds) {
              Settings.rewind = Duration(seconds: duration);
              Settings.write();
            }
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              'Confirm',
              style: TextStyle(
                  color: Settings.colors[6],
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600),
            ),
          ),
        )
      ],
    );
  }
}

class ForceStop extends StatefulWidget {
  // const ForceStop({Key key}) : super(key: key);

  @override
  _ForceStopState createState() => _ForceStopState();
}

class _ForceStopState extends State<ForceStop> {
  int duration = Settings.forceStop.inHours;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Settings.colors[0],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      actionsPadding: EdgeInsets.fromLTRB(0, 0, 20, 5),
      contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 12),
      title: Text(
        'Force stop (hours)',
        style: TextStyle(
            color: Settings.colors[3],
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600),
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.1,
        decoration: BoxDecoration(
            color: Settings.theme.value == 'Dark'
                ? Settings.colors[2]
                : Settings.colors[1],
            borderRadius: BorderRadius.circular(25)),
        child: Center(
          child: NumberPicker(
              onChanged: (value) => setState(() => duration = value),
              value: duration,
              itemWidth: 70,
              minValue: 1,
              maxValue: 24,
              axis: Axis.horizontal,
              textStyle: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  color: Settings.colors[3]),
              selectedTextStyle: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                  color: Settings.colors[6])),
        ),
      ),
      actions: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              'Cancel',
              style: TextStyle(
                  color: Settings.colors[6],
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
        InkWell(
          onTap: () {
            if (duration != Settings.forceStop.inHours) {
              Settings.forceStop = Duration(hours: duration);
              Settings.write();
            }
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              'Confirm',
              style: TextStyle(
                  color: Settings.colors[6],
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600),
            ),
          ),
        )
      ],
    );
  }
}

class Equalizer extends StatefulWidget {
  // const Equalizer({Key key}) : super(key: key);

  @override
  _EqualizerState createState() => _EqualizerState();
}

class _EqualizerState extends State<Equalizer> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Settings.colors[0],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      actionsPadding: EdgeInsets.fromLTRB(0, 0, 20, 5),
      contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 12),
      title: Text(
        'Equalizer',
        style: TextStyle(
            color: Settings.colors[3],
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600),
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.1,
        decoration: BoxDecoration(
            color: Settings.theme.value == 'Dark'
                ? Settings.colors[2]
                : Settings.colors[1],
            borderRadius: BorderRadius.circular(25)),
        child: Center(
            child: Text('Coming soon',
                style: TextStyle(
                    color: Settings.colors[3],
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600))),
      ),
      actions: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              'Cancel',
              style: TextStyle(
                  color: Settings.colors[6],
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
        InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              'Confirm',
              style: TextStyle(
                  color: Settings.colors[6],
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600),
            ),
          ),
        )
      ],
    );
  }
}

class DefaultFolder extends StatefulWidget {
  // const DefaultFolder({Key key}) : super(key: key);

  @override
  _DefaultFolderState createState() => _DefaultFolderState();
}

class _DefaultFolderState extends State<DefaultFolder> {
  FileExplorerChooseDefault explorer = FileExplorerChooseDefault();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Settings.colors[0],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      actionsPadding: EdgeInsets.fromLTRB(0, 0, 20, 5),
      contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 12),
      title: Text(
        'Default Folder',
        style: TextStyle(
            color: Settings.colors[3],
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600),
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
            color: Settings.theme.value == 'Dark'
                ? Settings.colors[2]
                : Settings.colors[1],
            borderRadius: BorderRadius.circular(25)),
        child: Center(
            child: ValueListenableBuilder(
          valueListenable: explorer.path,
          builder: (context, value, _) {
            return FutureBuilder(
                future: explorer.directories(),
                builder: (context, AsyncSnapshot<Widget> snapshot) {
                  if (snapshot.hasData) {
                    return snapshot.data!;
                  } else {
                    return Container();
                  }
                });
          },
        )),
      ),
      actions: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              'Cancel',
              style: TextStyle(
                  color: Settings.colors[6],
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
        InkWell(
          onTap: () {
            if (explorer.path.value != FileExplorer.rootPath) {
              Settings.defaultFolder = explorer.path.value;
              Settings.write();
            }
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              'Confirm',
              style: TextStyle(
                  color: Settings.colors[6],
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600),
            ),
          ),
        )
      ],
    );
  }
}

class FileExplorerChooseDefault extends FileExplorer {
  Future<Widget> directories() async {
    List<FileSystemEntity> dirs = await this.listDir(this.path.value);
    dirs.sort((a, b) => a.path.compareTo(b.path));
    if (this.path.value != FileExplorer.rootPath) {
      dirs.insert(0, File(File(this.path.value).parent.path));
    }
    List<Widget> folders = [];
    dirs.forEach((directory) {
      String _path = directory.path;
      String _extension = extension(_path);
      if (FileExplorer.audioFormats.contains(_extension) ||
          (_extension == '' && Directory(_path).existsSync())) {
        folders.add(Column(
          children: [
            Expanded(
                flex: 3,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return Container(
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                            color: Settings.theme.value == 'Dark'
                                ? Settings.colors[1]
                                : Settings.colors[6],
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: Settings.theme.value == 'Dark'
                                ? [
                                    BoxShadow(
                                        color: Color.fromRGBO(0, 0, 0, 0.1),
                                        spreadRadius: 1,
                                        blurRadius: 5)
                                  ]
                                : [
                                    BoxShadow(
                                        color:
                                            Settings.colors[6].withOpacity(0.5),
                                        spreadRadius: 0.1,
                                        blurRadius: 10)
                                  ]),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                              onTap: () {
                                if (_extension == '') {
                                  this.navigateToDir(_path);
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: _extension == ''
                                  ? Icon(
                                      _path == File(this.path.value).parent.path
                                          ? Icons.subdirectory_arrow_left
                                          : Icons.folder,
                                      color: Settings.theme.value == 'Dark'
                                          ? Settings.colors[7]
                                          : Settings.colors[0],
                                      size: 40)
                                  : Center(
                                      child: Text(
                                      _extension,
                                      style: TextStyle(
                                          fontFamily: 'Open Sans',
                                          fontWeight: FontWeight.bold,
                                          color: Settings.theme.value == 'Dark'
                                              ? Settings.colors[7]
                                              : Settings.colors[0]),
                                    ))),
                        ));
                  },
                )),
            Expanded(
              flex: 1,
              child: Center(
                  child: Text(
                basename(_path) == '0' ? 'Internal Storage' : basename(_path),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Open Sans',
                    height: 1,
                    fontWeight: FontWeight.w600,
                    color: Settings.colors[3],
                    fontSize: 12),
              )),
            )
          ],
        ));
      }
    });
    return GridView.count(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      physics: BouncingScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 0.75,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      children: folders,
    );
  }
}

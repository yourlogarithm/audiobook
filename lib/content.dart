import 'package:audiobook/classes/book.dart';
import 'package:audiobook/pages/AddBookPage.dart';
import 'package:audiobook/pages/BookPage.dart';
import 'package:audiobook/pages/ChangeCoverPage.dart';
import 'package:audiobook/pages/HomePage.dart';
import 'package:audiobook/pages/SettingsPage.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'classes/settings.dart';

bool _defaultPage = true;

void moveHome() {
  Content.contentNavigatorKey.currentState!.popUntil(ModalRoute.withName('/'));
  _defaultPage = true;
  bottomBarIndex.value = 1;
}

class Content extends StatefulWidget {
  static final GlobalKey<NavigatorState> contentNavigatorKey =
      GlobalKey<NavigatorState>();

  @override
  _ContentState createState() => _ContentState();
}

class _ContentState extends State<Content> with SingleTickerProviderStateMixin {
  void replaceRoute(int index) {
    setState(() {
      bottomBarIndex.value = index;
    });
    switch (bottomBarIndex.value) {
      case 0:
        Content.contentNavigatorKey.currentState!.pushNamed('/library');
        break;
      case 1:
        Content.contentNavigatorKey.currentState!
            .popUntil(ModalRoute.withName('/'));
        break;
      case 2:
        Content.contentNavigatorKey.currentState!.pushNamed('/settings');
        break;
    }
  }

  Widget _item(int index, IconData icon, String text) {
    if (index == bottomBarIndex.value) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(child: Icon(icon, color: Colors.white)),
            Expanded(
              flex: 3,
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
              ),
            )
          ],
        ),
      );
    } else {
      EdgeInsets _padding = EdgeInsets.symmetric(horizontal: 15, vertical: 10);
      return GestureDetector(
        onTap: () => replaceRoute(index),
        child: Padding(
          padding: _padding,
          child: Icon(icon,
              color: Settings.theme.value == 'Dark'
                  ? Colors.white
                  : Settings.colors[4],
              size: 28),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Settings.theme,
      builder: (context, value, _) {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Settings.theme.value == 'Dark'
              ? Brightness.light
              : Brightness.dark,
        ));
        return WillPopScope(
            onWillPop: () async {
              setState(() {
                moveHome();
              });
              return false;
            },
            child: Scaffold(
              body: Stack(
                children: [
                  Container(
                    child: Navigator(
                      key: Content.contentNavigatorKey,
                      initialRoute: '/',
                      onGenerateRoute: (RouteSettings settings) {
                        Widget builder;
                        switch (settings.name) {
                          case '/':
                            builder = HomePage();
                            break;
                          case '/settings':
                            builder = SettingsPage();
                            break;
                          case '/library':
                            builder = Container(color: Colors.yellow);
                            break;
                          case '/bookPage':
                            Book book = settings.arguments as Book;
                            setState(() {
                              _defaultPage = false;
                            });
                            builder = BookPage(book: book);
                            break;
                          case '/addBook':
                            builder = AddBookPage();
                            setState(() {
                              _defaultPage = false;
                            });
                            break;
                          case '/changeCover':
                            Book book = settings.arguments as Book;
                            setState(() {
                              _defaultPage = false;
                            });
                            builder = ChangeCoverPage(book: book);
                            break;
                          default:
                            throw Exception('Invalid route: ${settings.name}');
                        }
                        // return MaterialPageRoute(
                        //     builder: builder, settings: settings);
                        return PageRouteBuilder(
                            transitionDuration: Duration(milliseconds: 300),
                            transitionsBuilder:
                                (context, animation, secAnimation, child) {
                              animation = CurvedAnimation(
                                  parent: animation, curve: Curves.easeIn);
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            pageBuilder: (context, animation, secAnimation) {
                              return builder;
                            });
                      },
                    ),
                  ),
                  _defaultPage
                      ? Positioned(
                          bottom: 0,
                          child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              height: MediaQuery.of(context).size.height * 0.08,
                              width: MediaQuery.of(context).size.width,
                              color: Colors.transparent,
                              child: ValueListenableBuilder(
                                valueListenable: bottomBarIndex,
                                builder: (context, value, _) {
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      AnimatedContainer(
                                        width: bottomBarIndex.value == 0
                                            ? MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.3
                                            : 54,
                                        decoration: bottomBarIndex.value == 0
                                            ? BoxDecoration(
                                                color: Settings.colors[6],
                                                borderRadius:
                                                    BorderRadius.circular(25))
                                            : BoxDecoration(),
                                        duration: Duration(milliseconds: 300),
                                        child: _item(0, Icons.menu, 'Library'),
                                      ),
                                      AnimatedContainer(
                                        width: bottomBarIndex.value == 1
                                            ? MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.3
                                            : 54,
                                        decoration: bottomBarIndex.value == 1
                                            ? BoxDecoration(
                                                color: Settings.colors[6],
                                                borderRadius:
                                                    BorderRadius.circular(25))
                                            : BoxDecoration(),
                                        duration: Duration(milliseconds: 300),
                                        child: _item(1, Icons.home, 'Home'),
                                      ),
                                      AnimatedContainer(
                                        width: bottomBarIndex.value == 2
                                            ? MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.3
                                            : 54,
                                        decoration: bottomBarIndex.value == 2
                                            ? BoxDecoration(
                                                color: Settings.colors[6],
                                                borderRadius:
                                                    BorderRadius.circular(25))
                                            : BoxDecoration(),
                                        duration: Duration(milliseconds: 300),
                                        child: _item(
                                            2, Icons.settings, 'Settings'),
                                      ),
                                    ],
                                  );
                                },
                              )),
                        )
                      : Container()
                ],
              ),
            ));
      },
    );
  }
}

ValueNotifier<int> bottomBarIndex = ValueNotifier(1);

class MyBottomBar extends StatefulWidget {
  // const MyBottomBar({Key key}) : super(key: key);

  @override
  _MyBottomBarState createState() => _MyBottomBarState();
}

class _MyBottomBarState extends State<MyBottomBar> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

import 'package:audiodept/classes/book.dart';
import 'package:audiodept/loading.dart';
import 'package:audiodept/pages/AddBookPage.dart';
import 'package:audiodept/pages/BookPage.dart';
import 'package:audiodept/pages/ChangeCoverPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'classes/settings.dart';
import 'pages/MainPage.dart';

bool moveBlocked = false;

void moveHome() {
  if (bottomBarIndex.value == -1) {
    Content.contentNavigatorKey.currentState!.pushReplacementNamed('/');
    if (bookPageContextMenu.value.runtimeType != Container){
      bookPageContextMenu.value = Container();
    }
  } else {
    mainPageController.animateToPage(1, duration: Duration(milliseconds: 300), curve: Curves.fastOutSlowIn);
  }
  bottomBarIndex.value = 1;
}

class Content extends StatefulWidget {
  static final GlobalKey<NavigatorState> contentNavigatorKey = GlobalKey<NavigatorState>();

  @override
  _ContentState createState() => _ContentState();
}

class _ContentState extends State<Content> with SingleTickerProviderStateMixin {

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Settings.theme,
      builder: (context, value, _) {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Settings.theme.value == 'Dark' ? Brightness.light : Brightness.dark,
        ));
        return WillPopScope(
            onWillPop: () async {
              if (bottomBarIndex.value != 1 && !moveBlocked) {
                moveHome();
              }
              return false;
            },
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              body: Navigator(
                key: Content.contentNavigatorKey,
                initialRoute: '/',
                onGenerateRoute: (RouteSettings settings) {
                  Widget builder;
                  switch (settings.name) {
                    case '/':
                      builder = MainPage();
                      break;
                    case '/bookPage':
                      BookProvider bookProvider = settings.arguments as BookProvider;
                      builder = BookPage(bookProvider: bookProvider);
                      bottomBarIndex.value = -1;
                      break;
                    case '/addBook':
                      builder = AddBookPage();
                      bottomBarIndex.value = -1;
                      break;
                    case '/changeCover':
                      BookProvider bookProvider = settings.arguments as BookProvider;
                      builder = ChangeCoverPage(bookProvider: bookProvider);
                      bottomBarIndex.value = -1;
                      break;
                    case '/loading':
                      builder = Loading(isFirst: false);
                      bottomBarIndex.value = -1;
                      break;
                    default:
                      throw Exception('Invalid route: ${settings.name}');
                  }
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
                onPopPage: (route, result) {
                  return route.didPop(result);
                },
              ),
            ));
      },
    );
  }
}

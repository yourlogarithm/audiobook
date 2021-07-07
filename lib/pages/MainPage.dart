import 'package:audiodept/widgets/scrollBehavior.dart';
import 'package:audiodept/classes/settings.dart';
import 'package:audiodept/pages/HomePage.dart';
import 'package:audiodept/pages/LibraryPage.dart';
import 'package:audiodept/pages/SettingsPage.dart';
import 'package:flutter/material.dart';

ValueNotifier<int> bottomBarIndex = ValueNotifier(1);
final PageController mainPageController = PageController(initialPage: 1);

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

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
        onTap: () {
          mainPageController.animateToPage(index, duration: Duration(milliseconds: 300), curve: Curves.fastOutSlowIn);
          bottomBarIndex.value = index;
        },
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
    return Container(
      color: Settings.colors[1],
      child: Stack(
        children: [
          ScrollConfiguration(
            behavior: MyBehavior(),
            child: PageView(
              scrollDirection: Axis.horizontal,
              controller: mainPageController,
              onPageChanged: (index) {
                bottomBarIndex.value = index;
              },
              children: [
                LibraryPage(),
                HomePage(),
                SettingsPage()
              ],
            ),
          ),
          Positioned(
              bottom: 0,
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  height: MediaQuery.of(context).size.height * 0.08,
                  width: MediaQuery.of(context).size.width,
                  color: Colors.transparent,
                  child: ValueListenableBuilder(
                    valueListenable: bottomBarIndex,
                    builder: (context, value, _) {
                      return ValueListenableBuilder(
                          valueListenable: Settings.theme,
                          builder: (context, value, _) {
                            return Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                AnimatedContainer(
                                  width: bottomBarIndex.value == 0 ? MediaQuery.of(context).size.width * 0.3 : 54,
                                  decoration: bottomBarIndex.value == 0 ? BoxDecoration(
                                      color: Settings.colors[6],
                                      borderRadius:
                                      BorderRadius.circular(25))
                                      : BoxDecoration(),
                                  duration: Duration(milliseconds: 300),
                                  child: _item(0, Icons.menu, 'Library'),
                                ),
                                AnimatedContainer(
                                  width: bottomBarIndex.value == 1 ? MediaQuery.of(context).size.width * 0.3 : 54,
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
                                  width: bottomBarIndex.value == 2 ? MediaQuery.of(context).size.width * 0.3 : 54,
                                  decoration: bottomBarIndex.value == 2
                                      ? BoxDecoration(
                                      color: Settings.colors[6],
                                      borderRadius:
                                      BorderRadius.circular(25))
                                      : BoxDecoration(),
                                  duration: Duration(milliseconds: 300),
                                  child: _item(2, Icons.settings, 'Settings'),
                                ),
                              ],
                            );
                      });
                    },
                  )
            )
          )
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';

class MobileScreenLayout extends StatefulWidget {
  const MobileScreenLayout({super.key});
  @override
  State<MobileScreenLayout> createState() => _MobileScreenLayoutState();
}

class _MobileScreenLayoutState extends State<MobileScreenLayout> {
  int _page = 0;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  void navigationTapped(int page) {
    pageController.jumpToPage(page);
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        physics: const BouncingScrollPhysics(),
        controller: pageController,
        onPageChanged: onPageChanged,
        children: homeMobileScreenItems(),
      ),
      bottomNavigationBar: CupertinoTheme(
        data: CupertinoThemeData(
          textTheme: CupertinoTextThemeData(
            tabLabelTextStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        child: CupertinoTabBar(
          backgroundColor: mobileBackgroundColor,
          activeColor: appPrimaryColor,
          inactiveColor: secondaryColor,
          currentIndex: _page,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
                color: _page == 0 ? appPrimaryColor : secondaryColor,
              ),
              label: 'Home',
              backgroundColor: mobileBackgroundColor,
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.search,
                color: _page == 1 ? appPrimaryColor : secondaryColor,
              ),
              label: 'Search',
              backgroundColor: mobileBackgroundColor,
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.post_add,
                color: _page == 2 ? appPrimaryColor : secondaryColor,
              ),
              label: 'Post',
              backgroundColor: mobileBackgroundColor,
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.notification_add_outlined,
                color: _page == 3 ? appPrimaryColor : secondaryColor,
              ),
              label: 'Notifications',
              backgroundColor: mobileBackgroundColor,
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
                color: _page == 4 ? appPrimaryColor : secondaryColor,
              ),
              label: 'Profile',
              backgroundColor: mobileBackgroundColor,
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
                color: _page == 5 ? appPrimaryColor : secondaryColor,
              ),
              label: 'More',
              backgroundColor: mobileBackgroundColor,
            ),
          ],
          onTap: navigationTapped,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';

class WebScreenLayout extends StatefulWidget {
  const WebScreenLayout({super.key});

  @override
  State<WebScreenLayout> createState() => _WebScreenLayoutState();
}

class _WebScreenLayoutState extends State<WebScreenLayout> {
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
    setState(() {
      _page = page;
    });
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUserrOrNull; // safer getter (see below)

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        centerTitle: false,
        title: SvgPicture.asset('assets/images/trevie.svg', height: 32),
        actions: [
          IconButton(
            onPressed: () => navigationTapped(0),
            icon: Icon(
              Icons.home,
              color: _page == 0 ? appPrimaryColor : secondaryColor,
            ),
          ),
          IconButton(
            onPressed: () => navigationTapped(1),
            icon: Icon(
              Icons.search,
              color: _page == 1 ? appPrimaryColor : secondaryColor,
            ),
          ),
          IconButton(
            onPressed: () => navigationTapped(2),
            icon: Icon(
              Icons.post_add,
              color: _page == 2 ? appPrimaryColor : secondaryColor,
            ),
          ),
          IconButton(
            onPressed: () => navigationTapped(3),
            icon: Icon(
              Icons.messenger_outline_rounded,
              color: _page == 3 ? appPrimaryColor : secondaryColor,
            ),
          ),
          IconButton(
            onPressed: () => navigationTapped(4),
            icon: Icon(
              Icons.notification_add_outlined,
              color: _page == 4 ? appPrimaryColor : secondaryColor,
            ),
          ),
          IconButton(
            onPressed: () => navigationTapped(5),
            icon: Icon(
              Icons.person,
              color: _page == 5 ? appPrimaryColor : secondaryColor,
            ),
          ),
        ],
      ),
      body: PageView(
        physics: const BouncingScrollPhysics(),
        controller: pageController,
        onPageChanged: onPageChanged,
        children: homeWebScreenItems(),
      ),
    );
  }
}

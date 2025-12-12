import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/widgets/nav_bar_button.dart';

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
      return Center(child: customCircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        centerTitle: false,
        title: SvgPicture.asset('assets/images/trevie.svg', height: 32),
        actions: [
          NavBarButton(icon: Icons.home, label: 'Trang chủ', isActive: _page == 0, onPress: () => navigationTapped(0)),
          NavBarButton(icon: Icons.search, label: 'Tìm kiếm', isActive: _page == 1, onPress: () => navigationTapped(1)),
          NavBarButton(icon: Icons.post_add, label: 'Thêm bài viết', isActive: _page == 2, onPress: () => navigationTapped(2)),
          NavBarButton(icon: Icons.messenger_outline_outlined, label: 'Trò chuyện', isActive: _page == 3, onPress: () => navigationTapped(3)),
          NavBarButton(icon: Icons.notification_add_outlined, label: 'Thông báo', isActive: _page == 4, onPress: () => navigationTapped(4)),
          NavBarButton(icon: Icons.person_outlined, label: 'Hồ sơ', isActive: _page == 5, onPress: () => navigationTapped(5)),
          NavBarButton(icon: Icons.settings_outlined, label: 'Cài đặt', isActive: _page == 6, onPress: () => navigationTapped(6)),
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

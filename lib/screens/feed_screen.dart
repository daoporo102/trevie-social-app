import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/widgets/compose_post_card.dart';
import 'package:social_media_app/widgets/post_card.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        centerTitle: false,
        title: SvgPicture.asset('assets/images/trevie.svg', height: 32),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.messenger_outline_rounded,
              color: primaryTextColor,
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 8 (here) + 8 (ComposePostCard.margin) = 16 total
          SliverPadding(
            padding: const EdgeInsets.only(top: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate(const [
                ComposePostCard(),
                SizedBox(height: 8),
                PostCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:social_media_app/widgets/compose_post_card.dart';

class HomeFeedScreen extends StatelessWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: 8),
        ComposePostCard(),
        // feed items below
      ],
    );
  }
}

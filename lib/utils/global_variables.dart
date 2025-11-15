import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/screens/add_post_screen.dart';
import 'package:social_media_app/screens/feed_screen.dart';
import 'package:social_media_app/screens/more_screen.dart';
import 'package:social_media_app/screens/profile_screen.dart';
import 'package:social_media_app/screens/search_screen.dart';
import 'package:social_media_app/utils/colors.dart';

const webScreenSize = 600;

// final userId = FirebaseAuth.instance.currentUser!.uid;

String? currentUserId() => FirebaseAuth.instance.currentUser?.uid;

List<Widget> homeMobileScreenItems() {
  final uid = currentUserId() ?? '';
  return [
    const FeedScreen(),
    const SearchScreen(),
    const AddPostScreen(),
    const Text('Notifications'),
    ProfileScreen(uid: uid),
    MoreScreen(uid: uid),
  ];
}

List<Widget> homeWebScreenItems() {
  final uid = currentUserId() ?? '';
  return [
    const FeedScreen(),
    const SearchScreen(),
    const AddPostScreen(),
    const Text('Chat'),
    const Text('Notifications'),
    ProfileScreen(uid: uid),
    MoreScreen(uid: uid),
  ];
}

Widget customTextButton({
  required IconData icon,
  required String label,
  required VoidCallback onPressed,
}) {
  return TextButton(
    onHover: (value) => {
      // You can add hover effects
      if (value)
        {
          // Mouse is hovering
        }
      else
        {
          // Mouse is not hovering
        },
    },
    onPressed: onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: primaryTextColor),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

Widget customCircularProgressIndicator() {
  return Center(
    child: CircularProgressIndicator(
      backgroundColor: secondaryColor,
      color: appPrimaryColor,
    ),
  );
}

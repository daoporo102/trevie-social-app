import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:social_media_app/screens/add_post_screen.dart';
import 'package:social_media_app/screens/feed_screen.dart';
import 'package:social_media_app/screens/profile_screen.dart';
import 'package:social_media_app/screens/search_screen.dart';

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
  ];
}

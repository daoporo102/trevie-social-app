import 'package:flutter/cupertino.dart';
import 'package:social_media_app/screens/add_post_screen.dart';
import 'package:social_media_app/screens/home_feed_screen.dart';

const webScreenSize = 600;

const homeScreenItems = [
  HomeFeedScreen(),
  Text('Search'),
  AddPostScreen(),
  Text('Favorites'),
  Text('Profile'),
];

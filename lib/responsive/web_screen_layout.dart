import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/providers/user_provider.dart';

class WebScreenLayout extends StatefulWidget {
  const WebScreenLayout({super.key});

  @override
  State<WebScreenLayout> createState() => _WebScreenLayoutState();
}

class _WebScreenLayoutState extends State<WebScreenLayout> {
  @override
  Widget build(BuildContext context) {
    // model.User user = Provider.of<UserProvider>(context).getUser;
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUserrOrNull; // safer getter (see below)

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      body: Center(
        child: Text("Hello ${user.email}", style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

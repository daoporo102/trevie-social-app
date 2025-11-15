import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/widgets/compose_widget.dart';
import 'package:social_media_app/widgets/post_card.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final postStream = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('datePublished', descending: true)
        .snapshots();

    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: width > webScreenSize
          ? null
          : AppBar(
              backgroundColor: width > webScreenSize
                  ? webBackgroundColor
                  : mobileBackgroundColor,
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: postStream,
        builder: (context, snapshot) {
          final hasData = snapshot.hasData && snapshot.data != null;
          final docs = hasData
              ? snapshot.data!.docs
              : const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

          // +1 for the compose post card
          final totalItems = docs.length + 1;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return customCircularProgressIndicator();
          }

          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: totalItems,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: width > webScreenSize ? width * 0.3 : 0,
                        vertical: width > webScreenSize ? 15 : 0,
                      ),
                      child: ComposePostCard(),
                    ),
                  ],
                );
              }

              //Post start from index 1
              final doc = docs[index - 1];

              return Container(
                margin: EdgeInsets.symmetric(
                  horizontal: width > webScreenSize ? width * 0.3 : 0,
                  vertical: 0,
                ),
                child: PostCard(snap: doc),
              );
            },
          );
        },
      ),
    );
  }
}

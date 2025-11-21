import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/firestore_method.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/comment_card.dart';
import 'package:social_media_app/widgets/custom_snack_bar.dart';
import 'package:social_media_app/widgets/custom_button.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();

  void postComment(
    String uid,
    String name,
    String profilePic,
    BuildContext context,
  ) async {
    try {
      String res = await FirestoreMethod().postComment(
        widget.postId,
        _commentController.text,
        uid,
        name,
        profilePic,
      );
      if (res != 'success') {
        if (context.mounted) {
          displaySnackBar(res, context, SnackBarType.error);
        }
      }
      setState(() {
        _commentController.text = "";
      });
    } catch (e) {
      avoidPrint(e.toString());
      if (context.mounted) {
        displaySnackBar(
          "Có lỗi xảy ra, vui lòng thử lại sau.",
          context,
          SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = Provider.of<UserProvider>(context).getUserrOrNull;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: width > webScreenSize
          ? null
          : AppBar(
              backgroundColor: mobileBackgroundColor,
              title: const Text('Bình luận'),
              centerTitle: false,
            ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: width > webScreenSize ? width * 0.3 : 0,
          vertical: 0,
        ),
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.postId)
              .collection('comments')
              .orderBy('datePublished', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return customCircularProgressIndicator();
            }

            return ListView.builder(
              itemBuilder: (context, index) => CommentCard(
                snap: (snapshot.data! as dynamic).docs[index].data(),
                postId: widget.postId,
              ),
              itemCount: (snapshot.data! as dynamic).docs.length,
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: kToolbarHeight,
          margin:
              EdgeInsets.symmetric(
                // horizontal for WEB/MOBILE
                horizontal: width > webScreenSize ? width * 0.3 : 0,
                vertical: 0,
              ).copyWith(
                // Handle vertical (Bottom) to avoid virtual keyboard covering widget
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: secondaryColor,
                radius: 16,
                child: user!.photoUrl.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: user.photoUrl,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              customCircularProgressIndicator(),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.error_outline_outlined,
                            size: 32,
                            color: primaryTextColor,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 40,
                        color: primaryTextColor,
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Bình luận với tư cách ${user.displayName}',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: CustomButton(
                  onPressed: () async {
                    postComment(
                      user.uid,
                      user.displayName,
                      user.photoUrl,
                      context,
                    );
                  },
                  child: const Text(
                    'Gửi',
                    style: TextStyle(
                      color: onPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

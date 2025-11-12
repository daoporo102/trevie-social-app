import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/firestore_method.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/comment_card.dart';
import 'package:social_media_app/widgets/custom_snack_bar.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();

  void postComment(String uid, String name, String profilePic) async {
    try {
      String res = await FirestoreMethod().postComment(widget.postId, _commentController.text, uid, name, profilePic);
      if(res!='success'){
        if (context.mounted) {
          displaySnackBar(res, context, SnackBarType.error);
        }
      }
      setState(() {
        _commentController.text = "";
      });
    } catch (e) {
      avoidPrint(e.toString());
      displaySnackBar("Có lỗi xảy ra, vui lòng thử lại sau.", context, SnackBarType.error);
    }
  }


  @override
  Widget build(BuildContext context) {
    final User? user = Provider.of<UserProvider>(context).getUserrOrNull;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: const Text('Bình luận'),
        centerTitle: false,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .orderBy('datePublished', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemBuilder: (context, index) => CommentCard(
              snap: (snapshot.data! as dynamic).docs[index].data(),
            ),
            itemCount: (snapshot.data! as dynamic).docs.length,
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: kToolbarHeight,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: user!.photoUrl.isNotEmpty
                    ? NetworkImage(user.photoUrl)
                    : null,
                radius: 16,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Bình luận như ${user.displayName}',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
                InkWell(
                onTap: () async {
                  postComment(user.uid, user.displayName, user.photoUrl);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: const Text(
                    'Gửi',
                    style: TextStyle(
                      color: appPrimaryColor,
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

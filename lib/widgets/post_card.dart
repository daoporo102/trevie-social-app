import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/firestore_method.dart';
import 'package:social_media_app/screens/comments_screen.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/like_animation.dart';

class PostCard extends StatefulWidget {
  final snap;
  const PostCard({super.key, required this.snap});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isLikeAnimating = false;
  // int commentLen = 0;

  @override
  void initState() {
    super.initState();
    // getComments();
  }

  // void getComments() async {
  //   try {
  //     QuerySnapshot snap = await FirebaseFirestore.instance
  //         .collection('posts')
  //         .doc(widget.snap['postId'])
  //         .collection('comments')
  //         .get();
  //     commentLen = snap.docs.length;
  //   } catch (e) {
  //     avoidPrint(e.toString());
  //     showSnackBar(e.toString(), context);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final User? user = Provider.of<UserProvider>(context).getUserrOrNull;
    final commentStream = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.snap['postId'])
        .collection('comments')
        .snapshots();
    return Container(
      color: mobileBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 10),
<<<<<<< Updated upstream
      child: Column(
        children: [
          //HEADER SECTION OF THE POST
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 16,
            ).copyWith(right: 0),
            child: Column(
=======
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: width > webScreenSize
                ? primaryTextColor
                : mobileBackgroundColor,
          ),
          color: mobileBackgroundColor,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            //HEADER SECTION OF THE POST
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 16,
              ).copyWith(right: 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(widget.snap['profImage']),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.snap['displayName'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat.yMMMd().format(
                                  widget.snap['datePublished'].toDate(),
                                ),
                                style: TextStyle(
                                  color: secondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => SimpleDialog(
                              backgroundColor: width > webScreenSize
                                  ? webBackgroundColor
                                  : mobileBackgroundColor,
                              title: const Text('Tùy chọn'),
                              children: [
                                SimpleDialogOption(
                                  padding: const EdgeInsets.all(16),
                                  child: const Text('Xoá bài viết'),
                                  onPressed: () async {
                                    FirestoreMethod().deletePost(
                                      widget.snap['postId'],
                                    );
                                    Navigator.of(context).pop();
                                    displaySnackBar(
                                      "Xoá bài viết thành công",
                                      context,
                                      SnackBarType.success,
                                    );
                                  },
                                ),
                                SimpleDialogOption(
                                  padding: const EdgeInsets.all(16),
                                  child: const Text('Chỉnh sửa bài viết'),
                                  onPressed: () {},
                                ),
                                SimpleDialogOption(
                                  padding: const EdgeInsets.all(16),
                                  child: const Text('Hủy'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.more_vert),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.snap['postText'],
                          style: TextStyle(color: primaryTextColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            //IMAGE SECTION OF THE POST
            GestureDetector(
              onTap: () async {
                // View image in full screen
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        backgroundColor: mobileBackgroundColor,
                        title: Text('Hình ảnh'),
                      ),
                      body: Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Image.network(
                            widget.snap['postUrl'] ?? '',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              onDoubleTap: () async {
                await FirestoreMethod().likePost(
                  widget.snap['postId'],
                  user!.uid,
                  widget.snap['likes'],
                );
                setState(() {
                  isLikeAnimating = true;
                });
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.35,
                    width: double.infinity,
                    child: Image.network(
                      //check if disconnect network
                      widget.snap['postUrl'] ?? '',
                      fit: BoxFit.contain,
                    ),
                  ),

                  AnimatedOpacity(
                    opacity: isLikeAnimating ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: LikeAnimation(
                      isAnimating: isLikeAnimating,
                      duration: const Duration(milliseconds: 400),
                      onEnd: () {
                        setState(() {
                          isLikeAnimating = false;
                        });
                      },
                      child: Icon(Icons.favorite, color: Colors.red, size: 120),
                    ),
                  ),
                ],
              ),
            ),

            //LIKE, COMMENT, SHARE SECTION OF THE POST
            Row(
>>>>>>> Stashed changes
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(widget.snap['profImage']),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.snap['displayName'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat.yMMMd().format(
                                widget.snap['datePublished'].toDate(),
                              ),
                              style: TextStyle(
                                color: secondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: ListView(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shrinkWrap: true,
                              children: ['Delete', 'Edit']
                                  .map(
                                    (e) => InkWell(
                                      onTap: () async {
                                        FirestoreMethod().deletePost(
                                          widget.snap['postId'],
                                        );
                                        Navigator.of(context).pop();
                                        showSnackBar(
                                          "Xoá bài thành công",
                                          context,
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 16,
                                        ),
                                        child: Text(e),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.more_vert),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.snap['postText'],
                        style: TextStyle(color: primaryTextColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          //IMAGE SECTION OF THE POST
          GestureDetector(
            onDoubleTap: () async {
              await FirestoreMethod().likePost(
                widget.snap['postId'],
                user!.uid,
                widget.snap['likes'],
              );
              setState(() {
                isLikeAnimating = true;
              });
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  width: double.infinity,
                  child: Image.network(
                    //check if disconnect network
                    widget.snap['postUrl'] ?? '',
                    fit: BoxFit.cover,
                  ),
                ),

                AnimatedOpacity(
                  opacity: isLikeAnimating ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: LikeAnimation(
                    isAnimating: isLikeAnimating,
                    duration: const Duration(milliseconds: 400),
                    onEnd: () {
                      setState(() {
                        isLikeAnimating = false;
                      });
                    },
                    child: Icon(Icons.favorite, color: Colors.red, size: 120),
                  ),
                ),
              ],
            ),
          ),

          //LIKE, COMMENT, SHARE SECTION OF THE POST
          Row(
            children: [
              LikeAnimation(
                isAnimating: widget.snap['likes'].contains(user?.uid),
                smallLike: true,
                child: IconButton(
                  onPressed: () async {
                    await FirestoreMethod().likePost(
                      widget.snap['postId'],
                      user!.uid,
                      widget.snap['likes'],
                    );
                  },
                  icon: widget.snap['likes'].contains(user?.uid)
                      ? const Icon(Icons.favorite, color: Colors.red)
                      : const Icon(Icons.favorite_border, color: Colors.white),
                ),
              ),
              //NUMBER OF LIKES CAN GO HERE
              DefaultTextStyle(
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                child: Text('${widget.snap['likes'].length} thích'),
              ),
              //NUMBER OF COMMENTS CAN GO HERE
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        CommentsScreen(postId: widget.snap['postId']),
                  ),
                ),
                icon: const Icon(Icons.comment_outlined),
              ),
              //NUMBER OF COMMENTS CAN GO HERE (live)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: commentStream,
                builder: (context, snapshot) {
                  final totalComments = snapshot.hasData
                      ? snapshot.data!.size
                      : 0;
                  return DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    child: Text('$totalComments bình luận'),
                  );
                },
              ),
              //NUMBER OF SHARES CAN GO HERE
              IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
              DefaultTextStyle(
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                child: const Text('9 chia sẻ'),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.bookmark_border),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/firestore_method.dart';
import 'package:social_media_app/screens/comments_screen.dart';
import 'package:social_media_app/screens/update_post_screen.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/utils/utils.dart';

import 'package:social_media_app/widgets/custom_snack_bar.dart';
import 'package:social_media_app/widgets/like_animation.dart';

class PostCard extends StatefulWidget {
  final snap;
  const PostCard({super.key, required this.snap});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isLikeAnimating = false;

  @override
  void initState() {
    super.initState();
    // getComments();
  }

  Future<void> _deletePost(BuildContext context) async {
    try {
      final User? user = Provider.of<UserProvider>(
        context,
        listen: false,
      ).getUserrOrNull;

      if (user == null) {
        if (context.mounted) {
          Navigator.of(context).pop();
          displaySnackBar(
            'Không tìm thấy thông tin người dùng',
            context,
            SnackBarType.error,
          );
        }
        return;
      }

      // Get snapData
      final snapData = _getSnapData();

      String res = await FirestoreMethod().deletePost(snapData['postId']);

      if (!context.mounted) return; // Check before any UI operation

      Navigator.of(context).pop(); // Close the dialog first

      if (context.mounted && res == 'success') {
        displaySnackBar(
          'Đã xóa bài viết thành công',
          context,
          SnackBarType.success,
        );
      } else {
        if (context.mounted) {
          Navigator.of(context).pop();
          displaySnackBar(res, context, SnackBarType.error);
        }
      }
    } catch (e) {
      if (context.mounted) {
        avoidPrint("Error to delete post: ${e.toString()}");

        if (!context.mounted) return; // Check before UI operation

        Navigator.of(context).pop(); // Close dialog if still open

        displaySnackBar(
          "Xóa bài viết thất bại, vui lòng thử lại sau",
          context,
          SnackBarType.error,
        );
      }
    }
  }

  // Helper to safely get data from snap (handles both DocumentSnapshot and Map)
  Map<String, dynamic> _getSnapData() {
    if (widget.snap is DocumentSnapshot) {
      return (widget.snap as DocumentSnapshot).data() as Map<String, dynamic>;
    } else if (widget.snap is Map<String, dynamic>) {
      return widget.snap as Map<String, dynamic>;
    } else {
      throw Exception('Unsupported snap type');
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = Provider.of<UserProvider>(context).getUserrOrNull;

    final snapData = _getSnapData();

    final commentStream = FirebaseFirestore.instance
        .collection('posts')
        .doc(snapData['postId'])
        .collection('comments')
        .snapshots();

    final width = MediaQuery.of(context).size.width;
    return Container(
      color: mobileBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 8),
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
        padding: const EdgeInsets.symmetric(vertical: 8),
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
                        backgroundImage: NetworkImage(snapData['profImage']),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                snapData['displayName'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat.yMMMd().add_jm().format(
                                  (snapData['lastDateModified']).toDate(),
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
                                if (user!.uid == snapData['uid']) ...[
                                  SimpleDialogOption(
                                    padding: const EdgeInsets.all(16),
                                    child: const Text(
                                      'Chỉnh sửa bài viết',
                                      style: TextStyle(color: primaryTextColor),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              UpdatePostScreen(snap: snapData),
                                        ),
                                      );
                                    },
                                  ),
                                  SimpleDialogOption(
                                    padding: const EdgeInsets.all(16),
                                    child: const Text(
                                      'Xóa bài viết',
                                      style: TextStyle(color: primaryTextColor),
                                    ),
                                    onPressed: () async {
                                      await _deletePost(context);
                                    },
                                  ),
                                ] else ...[
                                  SimpleDialogOption(
                                    padding: const EdgeInsets.all(16),
                                    child: const Text(
                                      'Báo cáo bài viết',
                                      style: TextStyle(color: primaryTextColor),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      displaySnackBar(
                                        'Tính năng sẽ được phát triển trong thời gian tới',
                                        context,
                                        SnackBarType.info,
                                      );
                                    },
                                  ),
                                ],
                                SimpleDialogOption(
                                  padding: const EdgeInsets.all(16),
                                  child: const Text(
                                    'Hủy',
                                    style: TextStyle(color: primaryTextColor),
                                  ),
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
                          snapData['postText'],
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 16,
                          ),
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
                            snapData['postUrl'] ?? '',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              onDoubleTap: () async {
                if (!mounted) return; // Add this check

                await FirestoreMethod().likePost(
                  snapData['postId'],
                  user!.uid,
                  snapData['likes'],
                );

                if (!mounted) return; // Check again before setState
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
                      snapData['postUrl'] ?? '',
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  // Like group (flexible)
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        LikeAnimation(
                          isAnimating: (snapData['likes'] as List).contains(
                            user?.uid,
                          ),
                          smallLike: true,
                          child: IconButton(
                            onPressed: () async {
                              await FirestoreMethod().likePost(
                                snapData['postId'],
                                user.uid,
                                snapData['likes'],
                              );
                            },
                            icon: snapData['likes'].contains(user!.uid)
                                ? const Icon(Icons.favorite, color: Colors.red)
                                : const Icon(
                                    Icons.favorite_border,
                                    color: primaryTextColor,
                                  ),
                          ),
                        ),
                        //NUMBER OF LIKES CAN GO HERE
                        Flexible(
                          child: Text(
                            '${(snapData['likes'] as List).length} thích',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Comment group (flexible)
                  Expanded(
                    child: StreamBuilder(
                      stream: commentStream,
                      builder:
                          (
                            context,
                            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                            snapshot,
                          ) {
                            int commentCount = 0;
                            if (snapshot.hasData) {
                              commentCount = snapshot.data!.docs.length;
                            }
                            return Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => CommentsScreen(
                                          postId: snapData['postId'],
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.comment_outlined,
                                    color: primaryTextColor,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    '$commentCount bình luận',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                    ),
                  ),

                  //Share group (flexible)
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        //NUMBER OF SHARES CAN GO HERE
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.share),
                        ),
                        Flexible(
                          child: const Text(
                            '9 chia sẻ',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bookmark group (flexible)
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.bookmark_border),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

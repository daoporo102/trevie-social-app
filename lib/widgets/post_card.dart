import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/models/post.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/firestore_method.dart';
import 'package:social_media_app/screens/comments_screen.dart';
import 'package:social_media_app/screens/update_post_screen.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/custom_button.dart';
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

  Future<void> _openShareBottomSheet(
    BuildContext context,
    Map<String, dynamic> snapData,
    String displayName,
    String profImage,
    String uid,
  ) async {
    final TextEditingController textPostController = TextEditingController();

    // Fetch the post data FIRST
    Post originalPost = Post.fromSnap(
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(snapData['postId'])
          .get(),
    );

    // Check if context is still valid after async operation
    if (!context.mounted) return;

    showModalBottomSheet(
      useSafeArea: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: mobileBackgroundColor,
      // Dim the background less or change color
      barrierColor: primaryTextColor.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16.0,
            right: 16.0,
            top: 16.0,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Chia sẻ bài viết",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // TEXTFIELD
                  TextField(
                    controller: textPostController,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: "Nhập nội dung bài chia sẻ...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // SHARE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      onPressed: () async {
                        final String res;
                        // check if is a reshare post or not
                        if (snapData['originalPostId'] != null) {
                          // if is a reshare post, we need to get the original post
                          Post originalResharePost = Post.fromSnap(
                            await FirebaseFirestore.instance
                                .collection('posts')
                                .doc(snapData['originalPostId'])
                                .get(),
                          );
                          res = await FirestoreMethod().resharePost(
                            textPostController.text.trim(),
                            originalResharePost,
                            uid,
                            displayName,
                            profImage,
                          );
                          if (res != 'success') {
                            if (!context.mounted) return;
                            displaySnackBar(res, context, SnackBarType.error);
                            return;
                          }

                          if (!context.mounted) return;
                          Navigator.pop(context); // Close the bottom sheet
                          displaySnackBar(
                            'Chia sẻ bài viết thành công',
                            context,
                            SnackBarType.success,
                          );
                        } else {
                          // This is an original post
                          res = await FirestoreMethod().resharePost(
                            textPostController.text.trim(),
                            originalPost,
                            uid,
                            displayName,
                            profImage,
                          );
                          if (res != 'success') {
                            if (!context.mounted) return;
                            displaySnackBar(res, context, SnackBarType.error);
                            return;
                          }

                          if (!context.mounted) return;
                          Navigator.pop(context); // Close the bottom sheet
                          displaySnackBar(
                            'Chia sẻ bài viết thành công',
                            context,
                            SnackBarType.success,
                          );
                        }
                      },
                      child: const Text(
                        'Chia sẻ',
                        style: TextStyle(fontSize: 16, color: onPrimaryColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUserrOrNull; // safer getter (see below)
    if (user == null) {
      return customCircularProgressIndicator();
    }

    final snapData = _getSnapData();

    // Check if this is a reshared post
    final bool isResharePost = snapData['originalPostId'] != null;

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
                              Row(
                                children: [
                                  Text(
                                    snapData['displayName'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  // Display admin badge
                                  if (snapData['role'] == "admin") ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.admin_panel_settings,
                                      size: 16,
                                      color: appPrimaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Quản trị viên',
                                        style: TextStyle(
                                          color: appPrimaryColor,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                  // Display reshare indicator
                                  if (isResharePost) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.repeat,
                                      size: 16,
                                      color: secondaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'đã chia sẻ',
                                        style: TextStyle(
                                          color: secondaryColor,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                DateFormat('HH:mm dd MMM, y', 'vi').format(
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
                      // MORE BUTTON
                      IconButton(
                        onPressed: () async {
                          // For reshares, check if original post exists first
                          bool canEdit = true;
                          if (isResharePost && user.uid == snapData['uid']) {
                            try {
                              final originalPostDoc = await FirebaseFirestore
                                  .instance
                                  .collection('posts')
                                  .doc(snapData['originalPostId'])
                                  .get();

                              canEdit =
                                  originalPostDoc.exists &&
                                  originalPostDoc.data() != null;
                            } catch (e) {
                              canEdit = false;
                              avoidPrint("Error checking original post: $e");
                            }
                          }

                          if (!context.mounted) return;

                          showDialog(
                            context: context,
                            builder: (context) => SimpleDialog(
                              backgroundColor: width > webScreenSize
                                  ? webBackgroundColor
                                  : mobileBackgroundColor,
                              title: const Text('Tùy chọn'),
                              children: [
                                if (user.uid == snapData['uid']) ...[
                                  // Only show edit if original post exists (or not a reshare)
                                  if (!isResharePost || canEdit)
                                    SimpleDialogOption(
                                      padding: const EdgeInsets.all(16),
                                      child: const Text(
                                        'Chỉnh sửa bài viết',
                                        style: TextStyle(
                                          color: primaryTextColor,
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                UpdatePostScreen(
                                                  snap: snapData,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  if (isResharePost && !canEdit)
                                    SimpleDialogOption(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: const [
                                          Icon(
                                            Icons.info_outline,
                                            color: secondaryColor,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Chỉnh sửa bài viết',
                                              style: TextStyle(
                                                color: secondaryColor,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        displaySnackBar(
                                          'Bài viết gốc đã bị xóa, không thể chỉnh sửa',
                                          context,
                                          SnackBarType.info,
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

                  // Show reshare's text (if they added any)
                  if (snapData['postText'].isNotEmpty) ...[
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
                ],
              ),
            ),

            // ORIGINAL POST SECTION (if this is a reshare)
            if (isResharePost) ...[
              const SizedBox(height: 4),
              StreamBuilder<DocumentSnapshot>(
                stream: snapData['originalPostId'] != null
                    ? FirebaseFirestore.instance
                          .collection('posts')
                          .doc(snapData['originalPostId'])
                          .snapshots()
                    : null,
                builder: (context, originalPostSnapshot) {
                  // Check loading state
                  if (originalPostSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return customCircularProgressIndicator();
                  }

                  // check if original post was deleted
                  if (!originalPostSnapshot.hasData ||
                      !originalPostSnapshot.data!.exists ||
                      originalPostSnapshot.data!.data() == null) {
                    return _buildErrorContainer('Bài viết gốc đã bị xóa.');
                  }

                  // Original post exists - display it with live data
                  final originalPostData =
                      originalPostSnapshot.data!.data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: mobileBackgroundColor.withValues(alpha: 0.5),
                      border: Border.all(color: secondaryColor),
                    ),
                    // padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Original post header
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundImage: NetworkImage(
                                  originalPostData['profImage'] ?? '',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                originalPostData['displayName'] ??
                                    'Tên người dùng',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Original post text
                        if (originalPostData['postText'] != null &&
                            originalPostData['postText']!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
                            child: Text(
                              originalPostData['postText'] ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        const SizedBox(height: 4),
                        // Original post image
                        if (originalPostData['postUrl'] != null &&
                            originalPostData['postUrl'].isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            child: Image.network(
                              originalPostData['postUrl'],
                              height: MediaQuery.of(context).size.height * 0.25,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildErrorContainer(
                                  'Không thể tải hình ảnh.',
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  );
                },
              ),
            ] else ...[
              // REGULAR IMAGE SECTION OF THE POST (if not a reshare)
              const SizedBox(height: 8),
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
                    user.uid,
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
                          // Add mounted check before setState
                          if (!mounted) return;
                          setState(() {
                            isLikeAnimating = false;
                          });
                        },
                        child: Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 120,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                            user.uid,
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
                            icon: snapData['likes'].contains(user.uid)
                                ? const Icon(Icons.favorite, color: Colors.red)
                                : const Icon(
                                    Icons.favorite_border,
                                    color: primaryTextColor,
                                  ),
                          ),
                        ),
                        //NUMBER OF LIKES CAN GO HERE
                        Flexible(
                          child:
                              snapData['likes'] != null &&
                                  snapData['likes'].length >= 1
                              ? Text(
                                  '${(snapData['likes'] as List).length} lượt thích',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : const Text(
                                  'Thích',
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
                                  child: commentCount >= 1
                                      ? Text(
                                          '$commentCount bình luận',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : const Text(
                                          'bình luận',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
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
                          onPressed: () {
                            _openShareBottomSheet(
                              context,
                              snapData,
                              user.displayName,
                              user.photoUrl,
                              user.uid,
                            );
                          },
                          icon: const Icon(Icons.share),
                        ),
                        Flexible(
                          child:
                              snapData['reshareCount'] != null &&
                                  snapData['reshareCount'] >= 1
                              ? Text(
                                  '${snapData['reshareCount']} chia sẻ',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : const Text(
                                  'chia sẻ',
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

  Widget _buildErrorContainer(String message) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: mobileBackgroundColor.withValues(alpha: 0.5),
        border: Border.all(color: secondaryColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: secondaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: primaryTextColor)),
          ),
        ],
      ),
    );
  }
}

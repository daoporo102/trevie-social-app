import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/models/post.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/firestore_method.dart';
import 'package:social_media_app/screens/comments_screen.dart';
import 'package:social_media_app/screens/image_gallery_screen.dart';
import 'package:social_media_app/screens/profile_screen.dart';
import 'package:social_media_app/screens/update_post_screen.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/custom_button.dart';
import 'package:social_media_app/widgets/custom_snack_bar.dart';
import 'package:social_media_app/widgets/like_animation.dart';
import 'package:social_media_app/widgets/reject_dialog.dart';

class PostCard extends StatefulWidget {
  final snap;
  const PostCard({super.key, required this.snap});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isLikeAnimating = false;
  StreamSubscription<DocumentSnapshot>? _reshareSubscription;
  // Stream for the original post in reshared posts
  Stream<DocumentSnapshot>? _originalPostStream;

  @override
  void initState() {
    super.initState();
    // Initialize the stream for the original post in reshared posts
    _initializeStream();
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the stream if the widget changes (important for ListView).
    final oldSnap = _getSnapDataFromSnap(oldWidget.snap);
    final newSnap = _getSnapData();
    if (oldSnap['originalPostId'] != newSnap['originalPostId']) {
      _initializeStream();
    }
  }

  Map<String, dynamic> _getSnapDataFromSnap(dynamic snap) {
    if (snap is DocumentSnapshot) {
      return (snap).data() as Map<String, dynamic>;
    } else if (snap is Map<String, dynamic>) {
      return snap;
    } else {
      return {};
    }
  }

  // Initialize the stream for the original post in reshared posts
  void _initializeStream() {
    final snapData = _getSnapData();
    if (snapData['originalPostId'] != null) {
      _originalPostStream = FirebaseFirestore.instance
          .collection('posts')
          .doc(snapData['originalPostId'])
          .snapshots();
    } else {
      _originalPostStream = null;
    }
  }

  @override
  void dispose() {
    // Cancel any active subscriptions
    _reshareSubscription?.cancel();
    super.dispose();
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

    // Capture root context BEFORE showing bottom sheet
    final rootContext = context;

    try {
      // Fetch the post document and check if the field exists before converting.
      final postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(snapData['postId'])
          .get();

      if (!postDoc.exists || postDoc.data() == null) {
        if (!context.mounted) return;
        displaySnackBar(
          'Bài viết không tồn tại hoặc đã bị xóa',
          rootContext,
          SnackBarType.error,
        );
        return;
      }

      // Now safe to convert
      Post originalPost = Post.fromSnap(postDoc);

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
                          // Close the bottom sheet first
                          Navigator.pop(context);

                          // check if is a reshare post or not
                          if (snapData['originalPostId'] != null) {
                            // if is a reshare post, we need to get the original post
                            try {
                              final originalReshareDoc = await FirebaseFirestore
                                  .instance
                                  .collection('posts')
                                  .doc(snapData['originalPostId'])
                                  .get();

                              if (!originalReshareDoc.exists ||
                                  originalReshareDoc.data() == null) {
                                if (!rootContext.mounted) return;
                                displaySnackBar(
                                  'Bài viết gốc đã bị xóa',
                                  rootContext,
                                  SnackBarType.error,
                                );
                                return;
                              }

                              Post originalResharePost = Post.fromSnap(
                                originalReshareDoc,
                              );

                              res = await FirestoreMethod().resharePost(
                                textPostController.text.trim(),
                                originalResharePost,
                                uid,
                                displayName,
                                profImage,
                              );
                            } catch (e) {
                              if (!rootContext.mounted) return;
                              avoidPrint(
                                "Error fetching original reshare post: $e",
                              );
                              displaySnackBar(
                                "Có lỗi xảy ra, vui lòng thử lại sau.",
                                rootContext,
                                SnackBarType.error,
                              );
                              return;
                            }
                          } else {
                            // This is an original post
                            res = await FirestoreMethod().resharePost(
                              textPostController.text.trim(),
                              originalPost,
                              uid,
                              displayName,
                              profImage,
                            );
                          }

                          // Fix: check for whitespace (not empty string) instead of always-true ''
                          if (res.length != 36 || res.contains(' ')) {
                            if (!rootContext.mounted) return;
                            displaySnackBar(
                              "Có lỗi xảy ra, vui lòng thử lại sau.",
                              rootContext,
                              SnackBarType.error,
                            );
                            avoidPrint("DEBUG - Reshare failed: $res");
                          } else {
                            if (!rootContext.mounted) return;
                            // pass rootContext to listener
                            _listenToReshareStatus(res, rootContext);
                            avoidPrint("DEBUG - Reshare success with ID: $res");
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
    } catch (e) {
      avoidPrint("Error in _openShareBottomSheet: $e");
      if (!rootContext.mounted) return;
      displaySnackBar(
        "Có lỗi xảy ra khi tải bài viết, vui lòng thử lại sau",
        rootContext,
        SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUserrOrNull; // safer getter (see below)
    if (user == null) {
      return customCircularProgressIndicator();
    }

    final snapData = _getSnapData();

    // Get image URLs directly
    final List<String> imageUrls =
        snapData['postUrls'] != null && snapData['postUrls'] is List
        ? List<String>.from(snapData['postUrls'])
        : [];

    // Extract status and adminReason if needed
    final status = snapData['status'] as String?;
    final adminReason = snapData['adminReason'] as String?;
    // final aiReason = snapData['aiReason'] as String?;
    final aiReasonImage = snapData['aiReasonImage'] as String?;
    final aiReasonText = snapData['aiReasonText'] as String?;

    String rejectionReason = "";
    List<String> reasons = [];
    if (aiReasonImage != null && aiReasonImage.isNotEmpty) {
      reasons.add("Hình ảnh: $aiReasonImage");
    }
    if (aiReasonText != null && aiReasonText.isNotEmpty) {
      reasons.add("Văn bản: $aiReasonText");
    }
    if (reasons.isNotEmpty) {
      rejectionReason = reasons.join("\n");
    } else {
      rejectionReason =
          snapData['adminReason'] ?? "Vi phạm tiêu chuẩn cộng đồng";
    }

    bool isRejected = status == 'rejected';
    String rejectionTitle = "";
    // Set content opacity based on rejection status
    final double contentOpacity = isRejected ? 0.5 : 1.0;

    if (isRejected) {
      if (adminReason != null && adminReason.isNotEmpty) {
        rejectionTitle = "Bài viết đã bị Admin gỡ";
        rejectionReason = "Lý do: $adminReason";
      } else if (reasons.isNotEmpty) {
        rejectionTitle = "Bài viết đã bị AI gỡ";
        rejectionReason = "Lý do: ${reasons.join("\n")}";
      } else {
        rejectionTitle = "Bài viết đã bị từ chối";
        rejectionReason = "Vi phạm tiêu chuẩn cộng đồng";
      }
    }

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
            // REJECTION NOTICE SECTION
            if (isRejected)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: errorBackgroundColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: errorBackgroundColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: errorBackgroundColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rejectionTitle,
                            style: const TextStyle(
                              color: errorBackgroundColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rejectionReason,
                            style: const TextStyle(
                              color: errorBackgroundColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            //HEADER SECTION OF THE POST
            Opacity(
              opacity: contentOpacity,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 16,
                ).copyWith(right: 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProfileScreen(uid: snapData['uid']),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(
                              snapData['profImage'],
                            ),
                          ),
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
                                    InkWell(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => ProfileScreen(
                                              uid: snapData['uid'],
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        snapData['displayName'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                        style: TextStyle(
                                          color: primaryTextColor,
                                        ),
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
                                        style: TextStyle(
                                          color: primaryTextColor,
                                        ),
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
            ),

            // ORIGINAL POST SECTION (if this is a reshare)
            if (isResharePost) ...[
              const SizedBox(height: 4),
              StreamBuilder<DocumentSnapshot>(
                stream: _originalPostStream,
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

                  if ((originalPostSnapshot.data!.data()
                          as Map<String, dynamic>)['status'] ==
                      'rejected') {
                    return _buildErrorContainer(
                      'Bài viết gốc đã bị ẩn do vi phạm tiêu chuẩn cộng đồng.',
                    );
                  }

                  // Original post exists - display it with live data
                  final originalPostData =
                      originalPostSnapshot.data!.data() as Map<String, dynamic>;

                  return GestureDetector(
                    onDoubleTap: () => _handleDoubleTapLike(snapData),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: mobileBackgroundColor.withValues(alpha: 0.5),
                        border: Border.all(color: secondaryColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Original post header
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ProfileScreen(
                                      uid: originalPostData['uid'],
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundImage:
                                        (originalPostData['profImage'] !=
                                                null &&
                                            (originalPostData['profImage']
                                                    as String)
                                                .isNotEmpty)
                                        ? NetworkImage(
                                            originalPostData['profImage'],
                                          )
                                        : null,
                                    child:
                                        (originalPostData['profImage'] ==
                                                null ||
                                            (originalPostData['profImage']
                                                    as String)
                                                .isEmpty)
                                        ? const Icon(Icons.person, size: 12)
                                        : null,
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
                          // Original post images (for single or multiple)
                          Builder(
                            builder: (context) {
                              // Direct image URL assignment
                              List<String> originalImageUrls =
                                  originalPostData['postUrls'] != null &&
                                      originalPostData['postUrls'] is List
                                  ? List<String>.from(
                                      originalPostData['postUrls'],
                                    )
                                  : [];

                              if (originalImageUrls.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              // Reuse the existing image grid builder
                              // Note: _buildImageGrid already has its own like animation
                              try {
                                return _buildImageGrid(
                                  originalImageUrls,
                                  snapData, // Pass the RESHARE post data for liking
                                );
                              } catch (e) {
                                avoidPrint(
                                  'Error building original post images: $e',
                                );
                                return _buildErrorContainer(
                                  'Không thể tải hình ảnh.',
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ] else ...[
              // REGULAR IMAGE SECTION OF THE POST (if not a reshare)
              const SizedBox(height: 8),
              Opacity(
                opacity: contentOpacity,
                child: _buildImageGrid(imageUrls, snapData),
              ),
            ],
            //LIKE, COMMENT, SHARE SECTION OF THE POST
            if (!isRejected) ...[
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
                                  ? const Icon(
                                      Icons.favorite,
                                      color: Colors.red,
                                    )
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
                                    '${(snapData['likes'] as List).length}${width > 400 ? ' lượt thích' : ''}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : (width > 400)
                                ? const Text(
                                    'Thích',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : const SizedBox(),
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
                                            '$commentCount${width > 400 ? ' bình luận' : ''}',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : (width > 400)
                                        ? const Text(
                                            'Bình luận',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : const SizedBox(),
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
                                    '${snapData['reshareCount']}${width > 400 ? ' chia sẻ' : ''}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : (width > 400)
                                ? const Text(
                                    'Chia sẻ',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : const SizedBox(),
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

  // Update the listener method
  void _listenToReshareStatus(String postId, BuildContext rootContext) {
    // Cancel any previous subscription
    _reshareSubscription?.cancel();

    // Listen to the changes in the post document
    _reshareSubscription = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .snapshots()
        .listen(
          (snapshot) async {
            // Check if snapshot exists and widget is still mounted
            if (!snapshot.exists || !mounted) return;

            final data = snapshot.data() as Map<String, dynamic>;
            final status = data['status'] as String?;

            avoidPrint("DEBUG - Reshare Post $postId status updated: $status");

            // if status changed from 'processing', stop listening
            if (status != 'processing') {
              // Cancel the subscription
              await _reshareSubscription?.cancel();
              _reshareSubscription = null;

              // Check if context and widget are still valid
              if (!mounted || !rootContext.mounted) return;

              if (status == 'active') {
                displaySnackBar(
                  "Chia sẻ bài đăng thành công!",
                  rootContext,
                  SnackBarType.success,
                );
              } else if (status == 'rejected') {
                // get AI reason text
                final aiReasonText = data['aiReasonText'] as String?;
                final oldAiReason = data['aiReason'] as String?;

                // Logic fallback safe
                String displayReason = 'Vi phạm tiêu chuẩn cộng đồng';

                if (aiReasonText != null && aiReasonText.isNotEmpty) {
                  displayReason = "Văn bản: $aiReasonText";
                } else if (oldAiReason != null && oldAiReason.isNotEmpty) {
                  displayReason = oldAiReason;
                }

                // Fetch scores from violation_logs
                try {
                  final logSnapshot = await FirebaseFirestore.instance
                      .collection('violation_logs')
                      .where('targetId', isEqualTo: postId)
                      .orderBy('createdAt', descending: true)
                      .limit(1)
                      .get();

                  double? textScore;
                  double? imageScore;

                  if (logSnapshot.docs.isNotEmpty) {
                    final logData = logSnapshot.docs.first.data();
                    textScore = (logData['textScore'] as num?)?.toDouble();
                    imageScore = (logData['imageScore'] as num?)?.toDouble();
                  }

                  if (rootContext.mounted) {
                    RejectionDialog.show(
                      rootContext,
                      title: 'Bài chia sẻ bị từ chối',
                      description:
                          'Hệ thống AI đã phát hiện nội dung không phù hợp trong văn bản chia sẻ:',
                      reason: displayReason,
                      textScore: textScore,
                      imageScore: imageScore,
                    );
                  }
                } catch (e) {
                  // Fallback if fetching log fails
                  if (rootContext.mounted) {
                    RejectionDialog.show(
                      rootContext,
                      title: 'Bài chia sẻ bị từ chối',
                      description:
                          'Hệ thống AI đã phát hiện nội dung không phù hợp trong văn bản chia sẻ:',
                      reason: displayReason,
                    );
                  }
                  avoidPrint("Error fetching violation log for reshare: $e");
                }

                avoidPrint("DEBUG - Post $postId was rejected: $displayReason");
              } else {
                displaySnackBar(
                  "Bài đăng của bạn có trạng thái không xác định, vui lòng thử lại sau.",
                  rootContext,
                  SnackBarType.error,
                );
                avoidPrint("DEBUG - Post $postId has unknown status: $status");
              }
            }
          },
          onError: (error) {
            avoidPrint("DEBUG - Reshare listener error: $error");
            _reshareSubscription?.cancel();
            _reshareSubscription = null;
          },
        );

    // Safe timeout
    Future.delayed(const Duration(seconds: 15), () async {
      if (_reshareSubscription != null && mounted) {
        await _reshareSubscription?.cancel();
        _reshareSubscription = null;

        if (mounted && rootContext.mounted) {
          displaySnackBar(
            "Hết thời gian chờ xử lý bài chia sẻ. Vui lòng kiểm tra trạng thái bài đăng trong hồ sơ của bạn.",
            rootContext,
            SnackBarType.error,
          );
        }
      }
    });
  }

  // Helper method to build image grid
  Widget _buildImageGrid(
    List<String> imageUrls,
    Map<String, dynamic> snapData,
  ) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    // Single image - hiển thị full
    if (imageUrls.length == 1) {
      return _buildSingleImageView(imageUrls[0], snapData);
    }

    // Multiple images - Grid view
    return _buildMultipleImagesGrid(imageUrls, snapData);
  }

  // Build single image view (existing behavior)
  Widget _buildSingleImageView(String imageUrl, Map<String, dynamic> snapData) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                ImageGalleryScreen(imageUrls: [imageUrl], initialIndex: 0),
          ),
        );
      },
      onDoubleTap: () async {
        if (!mounted) return;

        setState(() {
          isLikeAnimating = true;
        });

        try {
          await FirestoreMethod().likePost(
            snapData['postId'],
            Provider.of<UserProvider>(
              context,
              listen: false,
            ).getUserrOrNull!.uid,
            snapData['likes'],
          );
        } catch (e) {
          if (context.mounted) {
            avoidPrint('Error liking post: $e');
            displaySnackBar(
              "Lỗi khi thích bài viết, vui lòng thử lại sau.",
              context,
              SnackBarType.error,
            );
          }
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 64),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: isLikeAnimating ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: LikeAnimation(
              isAnimating: isLikeAnimating,
              duration: const Duration(milliseconds: 400),
              onEnd: () {
                if (!mounted) return;
                setState(() {
                  isLikeAnimating = false;
                });
              },
              child: const Icon(Icons.favorite, color: Colors.red, size: 120),
            ),
          ),
        ],
      ),
    );
  }

  // Build grid for multiple images
  Widget _buildMultipleImagesGrid(
    List<String> imageUrls,
    Map<String, dynamic> snapData,
  ) {
    final int imageCount = imageUrls.length;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Grid layouts
        if (imageCount == 2)
          _buildTwoImagesLayout(imageUrls, snapData)
        else if (imageCount == 3)
          _buildThreeImagesLayout(imageUrls, snapData)
        else
          _buildFourPlusImagesLayout(imageUrls, snapData),

        // Like animation overlay
        AnimatedOpacity(
          opacity: isLikeAnimating ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: LikeAnimation(
            isAnimating: isLikeAnimating,
            duration: const Duration(milliseconds: 400),
            onEnd: () {
              if (!mounted) return;
              setState(() {
                isLikeAnimating = false;
              });
            },
            child: const Icon(Icons.favorite, color: Colors.red, size: 120),
          ),
        ),
      ],
    );
  }

  // Layout for 2 images
  Widget _buildTwoImagesLayout(
    List<String> imageUrls,
    Map<String, dynamic> snapData,
  ) {
    final width = MediaQuery.of(context).size.width;
    final bool isWeb = width > webScreenSize;

    final double containerWidth = isWeb ? width * 0.4 : width - 32;
    final double imageWidth = (containerWidth - 2) / 2;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: _buildGridImageItem(imageUrls[0], 0, imageUrls, snapData),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: _buildGridImageItem(imageUrls[1], 1, imageUrls, snapData),
            ),
          ),
        ],
      ),
    );
  }

  // Layout for 3 images
  Widget _buildThreeImagesLayout(
    List<String> imageUrls,
    Map<String, dynamic> snapData,
  ) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.35,
      child: Row(
        children: [
          // Large image on left
          Expanded(
            flex: 2,
            child: _buildGridImageItem(imageUrls[0], 0, imageUrls, snapData),
          ),
          const SizedBox(width: 2),
          // Two small images on right
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: _buildGridImageItem(
                    imageUrls[1],
                    1,
                    imageUrls,
                    snapData,
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: _buildGridImageItem(
                    imageUrls[2],
                    2,
                    imageUrls,
                    snapData,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Layout for 4+ images
  Widget _buildFourPlusImagesLayout(
    List<String> imageUrls,
    Map<String, dynamic> snapData,
  ) {
    final int displayCount = imageUrls.length > 4 ? 4 : imageUrls.length;
    final width = MediaQuery.of(context).size.width;
    final bool isWeb = width > webScreenSize;

    // Calculate container width based on screen size
    final double containerWidth = isWeb
        ? width *
              0.4 // Web: 40% screen (cuz it has padding 0.3 at PostCard)
        : width - 32; // Mobile: full width - padding

    // each image = (containerWidth - spacing) / 2
    final double imageSize = (containerWidth - 2) / 2;

    return Container(
      height: imageSize * 2 + 2, // 2 rows+ spacing
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1,
        ),
        itemCount: displayCount,
        itemBuilder: (context, index) {
          // Show "+N" overlay on last image if more than 4
          if (index == 3 && imageUrls.length > 4) {
            return _buildLastImageWithOverlay(
              imageUrls[3],
              imageUrls.length - 4,
              imageUrls,
              snapData,
            );
          }
          return _buildGridImageItem(
            imageUrls[index],
            index,
            imageUrls,
            snapData,
          );
        },
      ),
    );
  }

  // Single grid image item
  Widget _buildGridImageItem(
    String imageUrl,
    int index,
    List<String> allUrls,
    Map<String, dynamic> snapData,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                ImageGalleryScreen(imageUrls: allUrls, initialIndex: index),
          ),
        );
      },
      onDoubleTap: () => _handleDoubleTapLike(snapData),
      child: Container(
        decoration: BoxDecoration(color: secondaryColor.withValues(alpha: 0.1)),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image, color: secondaryColor),
          ),
        ),
      ),
    );
  }

  // Last image with "+N" overlay
  Widget _buildLastImageWithOverlay(
    String imageUrl,
    int remaining,
    List<String> allUrls,
    Map<String, dynamic> snapData,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                ImageGalleryScreen(imageUrls: allUrls, initialIndex: 3),
          ),
        );
      },
      onDoubleTap: () => _handleDoubleTapLike(snapData),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image, color: secondaryColor),
            ),
          ),
          Container(
            color: Colors.black54,
            child: Center(
              child: Text(
                '+$remaining',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to handle double tap like for grid images
  Future<void> _handleDoubleTapLike(Map<String, dynamic> snapData) async {
    if (!mounted) return;

    setState(() {
      isLikeAnimating = true;
    });

    try {
      await FirestoreMethod().likePost(
        snapData['postId'],
        Provider.of<UserProvider>(context, listen: false).getUserrOrNull!.uid,
        snapData['likes'],
      );
    } catch (e) {
      avoidPrint('Error liking post: $e');
      if (!mounted) return;
      displaySnackBar(
        "Lỗi khi thích bài viết, vui lòng thử lại sau.",
        context,
        SnackBarType.error,
      );
    }
  }
}

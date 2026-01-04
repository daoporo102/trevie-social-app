import 'package:social_media_app/utils/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:social_media_app/models/violation_log.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';

class ViolationsHistoryScreen extends StatelessWidget {
  const ViolationsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: const Text('Lịch sử vi phạm'),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(
          horizontal: width > webScreenSize ? width * 0.3 : 0,
          vertical: width > webScreenSize ? 15 : 0,
        ),
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('violation_logs')
              .where('uid', isEqualTo: currentUserUid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: customCircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.green,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Hồ sơ của bạn rất sạch!',
                      style: TextStyle(color: primaryTextColor, fontSize: 18),
                    ),
                    Text(
                      'Chưa ghi nhận vi phạm nào.',
                      style: TextStyle(color: secondaryColor),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                ViolationLog log = ViolationLog.fromSnap(
                  snapshot.data!.docs[index],
                );
                return _LogCard(log: log);
              },
            );
          },
        ),
      ),
    );
  }
}

class _LogCard extends StatefulWidget {
  final ViolationLog log;
  const _LogCard({required this.log});

  @override
  State<_LogCard> createState() => _LogCardState();
}

class _LogCardState extends State<_LogCard> {
  Map<String, dynamic>? _postData;
  bool _isLoadingPost = true;

  @override
  void initState() {
    super.initState();
    _fetchPostData();
  }

  Future<void> _fetchPostData() async {
    try {
      final postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.log.targetId)
          .get();

      // Check if the widget is still mounted before updating the state
      if (!mounted) return;

      if (postSnap.exists) {
        setState(() {
          _postData = postSnap.data();
        });
      }
    } catch (e) {
      avoidPrint("Error fetching post for violation log: $e");
    } finally {
      // Also check here, as the finally block always runs
      if (mounted) {
        setState(() {
          _isLoadingPost = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(log.createdAt);

    // Icon based on Action
    IconData actionIcon;
    String actionText;
    if (log.actionType == 'update') {
      actionIcon = Icons.edit_note;
      actionText = "Cập nhật bài";
    } else if (log.actionType == 'create') {
      actionIcon = Icons.post_add;
      actionText = "Đăng bài mới";
    } else if (log.actionType == 'reshare') {
      actionIcon = Icons.share;
      actionText = "Chia sẻ bài viết";
    } else {
      actionIcon = Icons.error_outline;
      actionText = "Hành động khác";
    }

    return Card(
      color: mobileBackgroundColor,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: errorBackgroundColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: errorBackgroundColor.withValues(alpha: 0.1),
          child: Icon(actionIcon, color: Colors.red),
        ),
        title: Text(
          log.reason,
          style: const TextStyle(
            color: errorBackgroundColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "$dateStr • $actionText",
              style: const TextStyle(color: secondaryColor, fontSize: 12),
            ),
            const SizedBox(height: 6),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: secondaryColor.withValues(alpha: 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. POST CONTEXT (Show only for 'update' or 'reshare')
                if (log.actionType == 'update' ||
                    log.actionType == 'reshare') ...[
                  if (_isLoadingPost)
                    Center(child: customCircularProgressIndicator())
                  else if (_postData != null) ...[
                    _buildPostPreview(_postData!),
                    const Divider(height: 24),
                  ],
                ],

                // 2. AI ANALYSIS
                const Text(
                  "Phân tích AI:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (log.textScore > 0) ...[
                      _buildScoreBadge("Điểm văn bản", log.textScore),
                      const SizedBox(width: 12),
                    ],
                    if (log.imageScore > 0)
                      _buildScoreBadge("Điểm hình ảnh", log.imageScore),
                  ],
                ),
                const Divider(height: 24),

                // 3. BLOCKED CONTENT
                const Text(
                  "Nội dung bị chặn:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 8),

                // TOXIC TEXT
                if (log.toxicText != null && log.toxicText!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log.toxicText!,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                // SHOW ALL TOXIC IMAGES IN DETAIL
                if (log.toxicImages.isNotEmpty) ...[
                  if (log.toxicText != null && log.toxicText!.isNotEmpty)
                    const SizedBox(height: 12),

                  const Text(
                    "Các ảnh vi phạm:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: errorBackgroundColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Display each toxic image
                  ...log.toxicImages.map((toxicImage) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: errorBackgroundColor.withValues(alpha: 0.05),
                        border: Border.all(
                          color: errorBackgroundColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Photo number + Violation score
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Photo number
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: errorBackgroundColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Ảnh ${toxicImage.index}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: onPrimaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),

                              // Violation score
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: errorBackgroundColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: errorBackgroundColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.warning_rounded,
                                      color: errorBackgroundColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${(toxicImage.score * 100).toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        color: errorBackgroundColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Specific reason for violation
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: errorBackgroundColor.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: errorBackgroundColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    toxicImage.reason,
                                    style: const TextStyle(
                                      color: errorBackgroundColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Display toxic image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              children: [
                                Image.network(
                                  toxicImage.url,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Container(
                                          height: 180,
                                          color: secondaryColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                              color: appPrimaryColor,
                                            ),
                                          ),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 180,
                                        decoration: BoxDecoration(
                                          color: secondaryColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.broken_image_rounded,
                                                color: secondaryColor,
                                                size: 48,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                "Ảnh đã bị xóa hoặc không tải được",
                                                style: TextStyle(
                                                  color: secondaryColor,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                ),

                                // Blurred overlay to mark toxic images
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          primaryTextColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          errorBackgroundColor.withValues(
                                            alpha: 0.1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  }),
                ]
                // Fallback: If there are no toxic images but there is a toxic Image_Url (backward compatible)
                else if (log.toxicImageUrl != null &&
                    log.toxicImageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    "Ảnh vi phạm:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: errorBackgroundColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      log.toxicImageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: secondaryColor.withValues(alpha: 0.1),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: secondaryColor,
                                size: 32,
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Ảnh đã bị xóa hoặc không tải được",
                                style: TextStyle(color: secondaryColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Xử lý bởi: ${log.moderatedBy}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget to show post preview
  Widget _buildPostPreview(Map<String, dynamic> postData) {
    final bool isReshare = postData['originalPostId'] != null;

    // Get a list of image URLs
    List<String>? postUrls;
    if (postData['postUrls'] != null && postData['postUrls'] is List) {
      postUrls = List<String>.from(postData['postUrls']);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ngữ cảnh bài đăng:",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        // Case 1: It's a regular post (for 'create' or 'update' violations)
        if (!isReshare)
          _buildPostInfoBox(
            avatarUrl: postData['profImage'],
            displayName: postData['displayName'],
            postText: postData['postText'],
            postUrl: postData['postUrl'],
            postUrls: postUrls,
          ),
        // Case 2: It's a reshare post. We'll mimic the PostCard structure.
        if (isReshare)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: secondaryColor.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reshare author header
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage:
                            (postData['profImage'] != null &&
                                postData['profImage'].isNotEmpty)
                            ? NetworkImage(postData['profImage'])
                            : null,
                        child:
                            (postData['profImage'] == null ||
                                postData['profImage'].isEmpty)
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          postData['displayName'] ??
                              'Người dùng không xác định',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Reshare text
                if (postData['postText'] != null &&
                    postData['postText'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Text(
                      postData['postText'],
                      style: const TextStyle(color: primaryTextColor),
                    ),
                  ),
                // Nested original post
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: _buildPostInfoBox(
                    avatarUrl: postData['originalProfImage'],
                    displayName: postData['originalDisplayName'],
                    postText: postData['originalPostText'],
                    postUrl: postData['postUrl'],
                    isNested: true, // Add a flag for nested style
                    postUrls: postUrls,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Helper widget to build the post preview box
  Widget _buildPostInfoBox({
    String? avatarUrl,
    String? displayName,
    String? postText,
    String? postUrl,
    bool isNested = false, // Flag to control background color
    List<String>? postUrls, // for multiple images
  }) {
    // Identify the list of image URLs
    final List<String> imageUrls = [];
    if (postUrls != null && postUrls.isNotEmpty) {
      imageUrls.addAll(postUrls);
    } else if (postUrl != null && postUrl.isNotEmpty) {
      imageUrls.add(postUrl);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNested ? secondaryColor.withValues(alpha: 0.1) : null,
        border: Border.all(color: secondaryColor.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with avatar and name
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? const Icon(Icons.person, size: 16)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayName ?? 'Người dùng không xác định',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Post text
          if (postText != null && postText.isNotEmpty)
            Text(
              postText,
              style: const TextStyle(color: primaryTextColor),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

          // Post image with reason for violation
          if (imageUrls.isNotEmpty) ...[
            if (postText != null && postText.isNotEmpty)
              const SizedBox(height: 8),

            // Display each image along with the corresponding violation reason
            ...imageUrls.asMap().entries.map((entry) {
              final index = entry.key;
              final imageUrl = entry.value;

              // Find the toxic image corresponding to this URL
              final toxicImage = widget.log.toxicImages.firstWhere(
                (ti) => ti.url == imageUrl,
                orElse: () => widget.log.toxicImages.isNotEmpty
                    ? widget.log.toxicImages[0]
                    : null as dynamic,
              );
              return Container(
                margin: EdgeInsets.only(
                  bottom: index < imageUrls.length - 1 ? 12 : 0,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: errorBackgroundColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header với số thứ tự ảnh và điểm vi phạm (nếu có)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: errorBackgroundColor.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.warning_rounded,
                                color: errorBackgroundColor,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Ảnh ${index + 1} vi phạm',
                                style: const TextStyle(
                                  color: errorBackgroundColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: errorBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${(toxicImage.score * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: onPrimaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Lý do vi phạm (nếu có)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      color: Colors.red.shade50,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: errorBackgroundColor,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              toxicImage.reason,
                              style: const TextStyle(
                                color: errorBackgroundColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Ảnh
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        bottomLeft: const Radius.circular(8),
                        bottomRight: const Radius.circular(8),
                        topLeft: Radius.zero,
                        topRight: Radius.zero,
                      ),
                      child: Stack(
                        children: [
                          Image.network(
                            imageUrl,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 150,
                                  color: secondaryColor.withValues(alpha: 0.1),
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: secondaryColor,
                                      size: 32,
                                    ),
                                  ),
                                ),
                          ),
                          // Overlay mờ cho ảnh vi phạm
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    errorBackgroundColor.withValues(
                                      alpha: 0.15,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // Widget to show score badge
  Widget _buildScoreBadge(String title, double score) {
    Color color = errorBackgroundColor;
    if (score > 0.8) {
      color = errorBackgroundColor;
    } else if (score > 0.5) {
      color = Colors.orange;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: secondaryColor, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Text(
            "${(score * 100).toStringAsFixed(2)}%",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

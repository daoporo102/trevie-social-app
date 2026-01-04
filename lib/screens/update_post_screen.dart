import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/firestore_method.dart';
import 'package:social_media_app/responsive/mobile_screen_layout.dart';
import 'package:social_media_app/responsive/responsive_layout_screen.dart';
import 'package:social_media_app/responsive/web_screen_layout.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/custom_button.dart';
import 'package:social_media_app/widgets/custom_snack_bar.dart';
import 'package:social_media_app/widgets/reject_dialog.dart';

class UpdatePostScreen extends StatefulWidget {
  final snap;
  const UpdatePostScreen({super.key, required this.snap});

  @override
  State<UpdatePostScreen> createState() => _UpdatePostScreenState();
}

class _UpdatePostScreenState extends State<UpdatePostScreen> {
  List<Uint8List> _newImages = [];
  List<String> _existingImageUrls = [];

  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  bool _isReshare = false;
  bool _isAwaitingModeration = false;
  static const int maxTotalImages = 10;
  final ScrollController _scrollController = ScrollController();
  String _uploadStatus = '';

  // Add StreamSubscription to manage
  StreamSubscription<DocumentSnapshot>? _postStatusSubscription;

  @override
  void initState() {
    super.initState();
    final postData = widget.snap;
    // Initialize text controller with existing post text
    _textController.text = postData['postText'];

    // Initialize existing images
    _existingImageUrls = postData['postUrls'] != null && postData['postUrls'] is List
      ? List<String>.from(postData['postUrls'])
      : [];

    // Check if the post is a reshare
    _isReshare = postData['originalPostId'] != null;
  }

  Future<void> _selectImages() async {
    // Capture the State's context BEFORE async
    final scaffoldContext = context;

    return showDialog(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          backgroundColor: mobileBackgroundColor,
          title: const Text('Chọn ảnh cho bài đăng'),
          children: [
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Chụp ảnh'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                // Check if the total number of images exceeds the limit
                if (_existingImageUrls.length + _newImages.length >=
                    maxTotalImages) {
                  if (scaffoldContext.mounted) {
                    displaySnackBar(
                      'Bạn đã đạt giới hạn $maxTotalImages ảnh',
                      scaffoldContext,
                      SnackBarType.error,
                    );
                  }
                  return;
                }

                try {
                  Uint8List? file = await pickImage(ImageSource.camera);
                  if (!mounted) return;
                  if (file == null) {
                    // Use captured context with mounted check
                    if (scaffoldContext.mounted) {
                      displaySnackBar(
                        'Không thể chụp ảnh',
                        scaffoldContext,
                        SnackBarType.error,
                      );
                    }
                    return;
                  }
                  setState(() {
                    _newImages.add(file);
                  });
                } catch (e) {
                  if (!mounted) return;
                  if (scaffoldContext.mounted) {
                    displaySnackBar(
                      'Có lỗi xảy ra khi chụp ảnh',
                      scaffoldContext,
                      SnackBarType.error,
                    );
                  }
                  avoidPrint(e.toString());
                }
              },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Chọn ảnh từ thư viện'),
              onPressed: () async {
                try {
                  Navigator.of(dialogContext).pop();

                  final currentTotal =
                      _existingImageUrls.length + _newImages.length;
                  if (currentTotal >= maxTotalImages) {
                    if (scaffoldContext.mounted) {
                      displaySnackBar(
                        'Bạn đã đạt giới hạn $maxTotalImages ảnh',
                        scaffoldContext,
                        SnackBarType.error,
                      );
                    }
                    return;
                  }

                  List<Uint8List>? files = await pickMultipleImages();
                  if (!mounted) return;
                  if (files == null || files.isEmpty) {
                    if (scaffoldContext.mounted) {
                      displaySnackBar(
                        'Không có ảnh nào được chọn',
                        scaffoldContext,
                        SnackBarType.error,
                      );
                    }
                    return;
                  }
                  // Calculate remaining slots
                  int remainingSlots = maxTotalImages - currentTotal;

                  if (remainingSlots <= 0) {
                    if (scaffoldContext.mounted) {
                      displaySnackBar(
                        'Bạn đã đạt giới hạn $maxTotalImages ảnh',
                        scaffoldContext,
                        SnackBarType.error,
                      );
                    }
                    return;
                  }

                  // Only add photos within the limit.
                  if (files.length > remainingSlots) {
                    if (scaffoldContext.mounted) {
                      displaySnackBar(
                        'Chỉ có thể thêm $remainingSlots ảnh nữa (tối đa $maxTotalImages ảnh)',
                        scaffoldContext,
                        SnackBarType.warning,
                      );
                    }
                    files = files.sublist(0, remainingSlots);
                  }

                  setState(() {
                    _newImages.addAll(files!);
                  });

                  if (scaffoldContext.mounted) {
                    displaySnackBar(
                      'Đã thêm ${files.length} ảnh',
                      scaffoldContext,
                      SnackBarType.success,
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  if (scaffoldContext.mounted) {
                    displaySnackBar(
                      'Có lỗi xảy ra khi chọn ảnh',
                      scaffoldContext,
                      SnackBarType.error,
                    );
                  }
                  avoidPrint(e.toString());
                }
              },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void removeExistingImage(int index) {
    setState(() {
      if (index >= 0 && index < _existingImageUrls.length) {
        _existingImageUrls.removeAt(index);
      }
    });
  }

  void removeNewImage(int index) {
    setState(() {
      if (index >= 0 && index < _newImages.length) {
        _newImages.removeAt(index);
      }
    });
  }

  Future<void> updatePost(String postId) async {
    // Validate inputs
    if (_textController.text.isEmpty) {
      displaySnackBar(
        'Vui lòng nhập nội dung cho bài đăng',
        context,
        SnackBarType.error,
      );
      return;
    }

    if (_existingImageUrls.isEmpty && _newImages.isEmpty) {
      displaySnackBar(
        'Vui lòng chọn ít nhất một ảnh',
        context,
        SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isAwaitingModeration = true;
      _uploadStatus = 'Đang chuẩn bị...';
    });

    try {
      if (_isReshare) {
        String res = await FirestoreMethod().updateResharePost(
          postId,
          _textController.text.trim(),
        );

        if (!mounted) return;

        if (res == 'success') {
          _listenToPostStatus(postId);
        } else {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _isAwaitingModeration = false;
          });
          displaySnackBar(
            'Có lỗi xảy ra, vui lòng thử lại sau.',
            context,
            SnackBarType.error,
          );
        }
      } else {
        setState(() {
          _uploadStatus = 'Đang tải ảnh lên...';
        });
        // Regular post update
        List<Uint8List>? imagesToUpload = _newImages.isNotEmpty
            ? _newImages
            : null;

        // Get a list of original image URLs
        List<String> originalUrls = widget.snap['postUrls'] != null &&
                widget.snap['postUrls'] is List
            ? List<String>.from(widget.snap['postUrls'])
            : [];

        List<String> urlsToDelete = originalUrls
            .where((url) => !_existingImageUrls.contains(url))
            .toList();

        avoidPrint("DEBUG - Updating post:");
        avoidPrint("  New images: ${_newImages.length}");
        avoidPrint("  Existing URLs kept: ${_existingImageUrls.length}");
        avoidPrint("  URLs to delete: ${urlsToDelete.length}");

        String res = await FirestoreMethod().updatePost(
          postId,
          _textController.text.trim(),
          imagesToUpload,
          urlsToDelete.isNotEmpty ? urlsToDelete : null,
        );

        if (!mounted) return;

        if (res == 'success') {
          setState(() {
            _uploadStatus = 'Đang kiểm duyệt...';
          });
          _listenToPostStatus(postId);
        } else {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _isAwaitingModeration = false;
          });
          displaySnackBar(
            'Có lỗi xảy ra, vui lòng thử lại sau.',
            context,
            SnackBarType.error,
          );
          avoidPrint("Update post failed: $res");
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isAwaitingModeration = false;
      });
      avoidPrint("Exception in updatePost: $e");
      displaySnackBar(
        'Có lỗi xảy ra khi cập nhật bài đăng',
        context,
        SnackBarType.error,
      );
    }
  }

  // Manage subscriptions and increase timeouts.
  void _listenToPostStatus(String postId) {
    // Cancel previous subscription if exists
    _postStatusSubscription?.cancel();

    // Listen to post changes
    _postStatusSubscription = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .snapshots()
        .listen(
          (snapshot) async {
            if (!snapshot.exists || !mounted) return;

            final data = snapshot.data() as Map<String, dynamic>;
            final updateStatus = data['updateStatus'] as String?;
            final updateError = data['updateError'] as String?;
            final moderatedBy = data['moderatedBy'] as String?;

            if (!_isAwaitingModeration && updateStatus == 'failed') {
              avoidPrint("DEBUG - Ignoring old 'failed' status.");
              return;
            }

            avoidPrint(
              "DEBUG - Update Listener: By=$moderatedBy, Status=$updateStatus",
            );

            if (moderatedBy == null && updateStatus == null) return;

            // CASE 1: UPDATE FAILED
            if (moderatedBy == 'AI_Rollback' || updateStatus == 'failed') {
              await _postStatusSubscription?.cancel();
              _postStatusSubscription = null;

              if (!mounted) return;

              setState(() {
                _isLoading = false;
                _isAwaitingModeration = false;
              });

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

                  if (mounted) {
                    RejectionDialog.show(
                      context,
                      title: 'Cập nhật thất bại',
                      description:
                          'Nội dung chỉnh sửa chứa thông tin không phù hợp:',
                      reason: updateError ?? 'Vi phạm tiêu chuẩn cộng đồng.',
                      textScore: textScore,
                      imageScore: imageScore,
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  RejectionDialog.show(
                    context,
                    title: 'Cập nhật thất bại',
                    description:
                        'Nội dung chỉnh sửa chứa thông tin không phù hợp:',
                    reason: updateError ?? 'Vi phạm tiêu chuẩn cộng đồng.',
                  );
                }
                avoidPrint("Error fetching violation log: $e");
              }
            }
            // CASE 2: UPDATE APPROVED
            else if (moderatedBy == 'AI_Update' ||
                updateStatus == 'success' ||
                moderatedBy == 'system_failover') {
              await _postStatusSubscription?.cancel();
              _postStatusSubscription = null;

              if (!mounted) return;

              setState(() {
                _isLoading = false;
                _isAwaitingModeration = false;
              });

              displaySnackBar(
                "Cập nhật bài viết thành công!",
                context,
                SnackBarType.success,
              );

              clearImage();
              _textController.clear();

              // Navigate after clear
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const ResponsiveLayout(
                      mobileScreenLayout: MobileScreenLayout(),
                      webScreenLayout: WebScreenLayout(),
                    ),
                  ),
                  (route) => false,
                );
              }
            }
          },
          onError: (error) {
            avoidPrint("DEBUG - Post status listener error: $error");
            _postStatusSubscription?.cancel();
            _postStatusSubscription = null;

            if (mounted) {
              setState(() {
                _isLoading = false;
                _isAwaitingModeration = false;
              });
              displaySnackBar(
                "Có lỗi xảy ra khi theo dõi trạng thái bài đăng",
                context,
                SnackBarType.error,
              );
            }
          },
        );

    // INCREASE timeout to 60 seconds to handle large uploads
    Future.delayed(const Duration(seconds: 60), () async {
      if (!mounted) return;

      if (_isLoading && _isAwaitingModeration) {
        await _postStatusSubscription?.cancel();
        _postStatusSubscription = null;

        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _isAwaitingModeration = false;
        });

        avoidPrint("DEBUG - Post $postId update listener timed out after 60s.");

        displaySnackBar(
          'Đang xử lý cập nhật. Vui lòng kiểm tra bài đăng sau ít phút.',
          context,
          SnackBarType.info,
        );

        // Navigate to NewsFeed screen
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const ResponsiveLayout(
                mobileScreenLayout: MobileScreenLayout(),
                webScreenLayout: WebScreenLayout(),
              ),
            ),
            (route) => false,
          );
        }
      }
    });
  }

  void clearImage() {
    _newImages.clear();
    _existingImageUrls.clear();
  }

  @override
  void dispose() {
    // Cancel subscription before dispose
    _postStatusSubscription?.cancel();
    _postStatusSubscription = null;

    _textController.dispose();
    _scrollController.dispose();

    _newImages.clear();
    _existingImageUrls.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUserrOrNull; // safer getter (see below)
    if (user == null) {
      return customCircularProgressIndicator();
    }

    final postData = widget.snap;
    final postId = postData['postId'];

    // Calculate total images
    final totalImages = _existingImageUrls.length + _newImages.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: width > webScreenSize
            ? webBackgroundColor
            : mobileBackgroundColor,
        leading: width > webScreenSize
            ? null
            : IconButton(
                onPressed: () {
                  clearImage();
                  //Navigate back to feed screen
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const ResponsiveLayout(
                        mobileScreenLayout: MobileScreenLayout(),
                        webScreenLayout: WebScreenLayout(),
                      ),
                    ),
                    // remove all previous routes
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.arrow_back),
              ),
        title: width > webScreenSize
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Spacer(), // Push title to center
                  Text('Cập nhật bài đăng'),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      updatePost(postId);
                    },
                    child: const Text(
                      'Cập nhật',
                      style: TextStyle(
                        color: appPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Spacer(), // Push title to center
                ],
              )
            : const Text('Cập nhật bài đăng'),
        centerTitle: width > webScreenSize ? true : false,
        actions: width > webScreenSize
            ? null
            : [
                TextButton(
                  onPressed: () {
                    updatePost(postId);
                  },
                  child: const Text(
                    'Cập nhật',
                    style: TextStyle(
                      color: appPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: width > webScreenSize ? width * 0.3 : 0,
            vertical: width > webScreenSize ? 15 : 0,
          ),
          decoration: BoxDecoration(
            color: width > webScreenSize
                ? webBackgroundColor
                : mobileBackgroundColor,
            borderRadius: width > webScreenSize
                ? BorderRadius.circular(12)
                : null,
            border: Border.all(
              color: width > webScreenSize
                  ? primaryTextColor
                  : mobileBackgroundColor,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _isLoading
                  ? Column(
                      children: [
                        customLinearProgressIndicator(),
                        if (_uploadStatus.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _uploadStatus,
                              style: const TextStyle(
                                fontSize: 12,
                                color: secondaryColor,
                              ),
                            ),
                          ),
                      ],
                    )
                  : const Padding(padding: EdgeInsets.only(top: 0)),
              ?width > webScreenSize
                  ? null
                  : const Divider(color: secondaryColor),

              // User info section
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  spacing: 12,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: secondaryColor,
                      backgroundImage: user.photoUrl.isNotEmpty == true
                          ? NetworkImage(user.photoUrl)
                          : null,
                      child: user.photoUrl.isEmpty == true
                          ? const Icon(
                              Icons.account_circle,
                              size: 48,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Text input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: width > webScreenSize ? width * 0.3 : double.infinity,
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Viết mô tả của bạn...',
                      border: InputBorder.none,
                    ),
                    maxLines: 8,
                  ),
                ),
              ),
              const Divider(color: secondaryColor),

              // Show different UI for reshare vs regular post
              if (_isReshare) ...[
                // Show original post preview (read-only)
                _buildOriginalPostPreview(postData),
              ] else ...[
                // Show editable image section
                if (totalImages == 0)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CustomButton(
                      backgroundColor: appPrimaryColor,
                      onPressed: () => _selectImages(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.add_photo_alternate,
                            color: onPrimaryColor,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Thêm ảnh',
                            style: TextStyle(color: onPrimaryColor),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$totalImages/$maxTotalImages ảnh',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: totalImages >= maxTotalImages
                                    ? errorBackgroundColor
                                    : secondaryColor,
                              ),
                            ),
                            CustomButton(
                              backgroundColor: totalImages >= maxTotalImages
                                  ? secondaryColor
                                  : appPrimaryColor,
                              borderRadius: BorderRadius.circular(8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              onPressed: totalImages >= maxTotalImages
                                  ? () {} // No-op function when disabled
                                  : () => _selectImages(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: totalImages >= maxTotalImages
                                        ? Colors.grey
                                        : onPrimaryColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    totalImages >= maxTotalImages
                                        ? 'Đã đủ'
                                        : 'Thêm ảnh',
                                    style: TextStyle(
                                      color: totalImages >= maxTotalImages
                                          ? Colors.grey
                                          : onPrimaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Images list
                      Container(
                        height: 220,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                            },
                            scrollbars: width > webScreenSize,
                          ),
                          child: ListView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            children: [
                              // Existing images
                              ..._existingImageUrls.asMap().entries.map((
                                entry,
                              ) {
                                final index = entry.key;
                                final url = entry.value;
                                return _buildExistingImageItem(url, index);
                              }),

                              // New images
                              ..._newImages.asMap().entries.map((entry) {
                                final index = entry.key;
                                final imageData = entry.value;
                                return _buildNewImageItem(imageData, index);
                              }),
                            ],
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
    );
  }

  // Build original post preview (for reshare)
  Widget _buildOriginalPostPreview(Map<String, dynamic> postData) {
    // Get list of original post images
    List<String> originalImageUrls = postData['postUrls'] != null &&
            postData['postUrls'] is List
        ? List<String>.from(postData['postUrls'])
        : [];

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: mobileBackgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: secondaryColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original post author info
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundImage:
                    (postData['originalProfImage'] != null &&
                        postData['originalProfImage'].isNotEmpty)
                    ? NetworkImage(postData['originalProfImage'])
                    : null,
                child:
                    (postData['originalProfImage'] == null ||
                        postData['originalProfImage'].isEmpty)
                    ? const Icon(Icons.person, size: 12)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                postData['originalDisplayName'] ?? 'Người dùng không xác định',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          // Original post text
          if (postData['originalPostText'] != null &&
              postData['originalPostText'].isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              postData['originalPostText'],
              style: const TextStyle(color: primaryTextColor, fontSize: 14),
            ),
          ],

          // Original post images (support multiple images)
          if (originalImageUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildOriginalImagesPreview(originalImageUrls),
          ],

          const SizedBox(height: 8),
          const Text(
            'Bạn không thể chỉnh sửa nội dung gốc',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: secondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Build original images preview widget
  Widget _buildOriginalImagesPreview(List<String> imageUrls) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    // Single image - display normally
    if (imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          imageUrls[0],
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 200,
            color: secondaryColor.withValues(alpha: 0.1),
            child: const Center(
              child: Text(
                'Không thể tải ảnh gốc',
                style: TextStyle(color: primaryTextColor),
              ),
            ),
          ),
        ),
      );
    }

    // Multiple images - display in horizontal scrollable list
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(
              right: index < imageUrls.length - 1 ? 8 : 0,
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    imageUrls[index],
                    fit: BoxFit.cover,
                    width: 150,
                    height: 150,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 150,
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
                ),
                // Image counter badge
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1}/${imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Build existing image item (from server)
  Widget _buildExistingImageItem(String imageUrl, int index) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 200,
                height: 200,
                color: secondaryColor.withValues(alpha: 0.3),
                child: const Icon(Icons.broken_image, color: secondaryColor),
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          left: 12,
          child: Container(
            decoration: BoxDecoration(
              color: onPrimaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: secondaryColor),
              onPressed: () => removeExistingImage(index),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: appPrimaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Hiện tại',
              style: TextStyle(
                color: onPrimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Build new image item (local)
  Widget _buildNewImageItem(Uint8List imageData, int index) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              imageData,
              fit: BoxFit.cover,
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 200,
                height: 200,
                color: secondaryColor.withValues(alpha: 0.3),
                child: const Icon(Icons.broken_image, color: secondaryColor),
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          left: 12,
          child: Container(
            decoration: BoxDecoration(
              color: onPrimaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: secondaryColor),
              onPressed: () => removeNewImage(index),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Mới',
              style: TextStyle(
                color: onPrimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

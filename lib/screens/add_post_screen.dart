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
import 'package:social_media_app/widgets/custom_snack_bar.dart';
import 'package:social_media_app/widgets/custom_button.dart';
import 'package:social_media_app/widgets/reject_dialog.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  List<Uint8List> _images = [];
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  StreamSubscription<DocumentSnapshot>? _postSubscription; // Add this
  final ScrollController _scrollController = ScrollController();
  static const int maxTotalImages = 10;

  Future<void> _selectImage() async {
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

                // Check image limit
                if (_images.length >= maxTotalImages) {
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
                    _images.add(file);
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

                  // Check current images number
                  if (_images.length >= maxTotalImages) {
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
                        context,
                        SnackBarType.error,
                      );
                    }
                    return;
                  }

                  // Calculate images number can add more
                  int remainingSlots = maxTotalImages - _images.length;

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

                  //ONLY ADD IMAGES WITHIN THE LIMIT
                  if (files.length > remainingSlots) {
                    if (scaffoldContext.mounted) {
                      displaySnackBar(
                        'Chỉ có thể thêm $remainingSlots ảnh nữa (tối đa $maxTotalImages ảnh)',
                        scaffoldContext,
                        SnackBarType.warning,
                      );
                    }
                    // Only take the permitted number of images.
                    files = files.sublist(0, remainingSlots);
                  }

                  setState(() {
                    _images.addAll(files!);
                  });

                  // display successfully snackbar
                  if (scaffoldContext.mounted) {
                    displaySnackBar(
                      'Đã thêm ${files.length} ảnh (${_images.length}/$maxTotalImages)',
                      scaffoldContext,
                      SnackBarType.success,
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  if (scaffoldContext.mounted) {
                    displaySnackBar(
                      'Có lỗi xảy ra khi chọn ảnh từ thư viện',
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

  void removeImage(int index) {
    setState(() {
      if (index >= 0 && index < _images.length) {
        _images.removeAt(index);
      }
    });
  }

  void postImage(String uid, String displayName, String profImage) async {
    // Add debug logging
    avoidPrint("DEBUG - uid: $uid");
    avoidPrint("DEBUG - displayName: $displayName");
    avoidPrint("DEBUG - profImage: $profImage");
    avoidPrint("DEBUG - postText: ${_textController.text}");
    avoidPrint("DEBUG - image size: ${_images.length}");
    // Validate inputs
    if (_textController.text.isEmpty) {
      displaySnackBar(
        'Vui lòng nhập mô tả cho bài đăng',
        context,
        SnackBarType.error,
      );
      return;
    }

    if (_images.isEmpty) {
      displaySnackBar(
        'Vui lòng chọn ảnh để đăng bài',
        context,
        SnackBarType.error,
      );
      return;
    }

    // Add this check for profImage
    if (profImage.isEmpty) {
      displaySnackBar(
        'Vui lòng cập nhật ảnh đại diện trước khi đăng bài',
        context,
        SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      // Call the uploadPost method((At this point, the function returns either the postId or an error message.))
      String result = await FirestoreMethod().uploadPost(
        _textController.text.trim(),
        _images,
        uid,
        displayName,
        profImage,
      );

      avoidPrint("DEBUG - Upload result: $result"); // See what fails

      if (!mounted) return; // guard context after async

      // Check if the result is an error message (UUID length is 36 characters)
      // If it contains spaces or is too short, it's an error
      if (result.length != 36 || result.contains(' ')) {
        setState(() {
          _isLoading = false;
        });
        displaySnackBar(
          "Đã xảy ra lỗi khi đăng bài, vui lòng thử lại sau",
          context,
          SnackBarType.error,
        );
        avoidPrint("DEBUG - Post upload failed with message: $result");
      } else {
        // Upload successful, result is postId
        String postId = result;
        avoidPrint("DEBUG - Post uploaded with ID: $postId");
        setState(() {
          _isLoading = false;
        });

        _listenToPostStatus(postId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      avoidPrint(e.toString());
      displaySnackBar(
        "Có lỗi xảy ra, vui lòng thử lại sau.",
        context,
        SnackBarType.error,
      );
    }
  }

  // Update the listener method
  void _listenToPostStatus(String postId) {
    // Cancel any previous subscription
    _postSubscription?.cancel();

    // Listen the changes in the post document
    _postSubscription = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .snapshots()
        .listen(
          (snapshot) async {
            // Check if snapshot is not exists or widget is not mounted
            if (!snapshot.exists || !mounted) return;

            final data = snapshot.data() as Map<String, dynamic>;
            final status = data['status'] as String?;

            final aiReasonText = data['aiReasonText'] as String?;
            final aiReasonImage = data['aiReasonImage'] as String?;

            // Combine reasons if both exist
            String? displayReason;
            List<String> reasons = [];

            if (aiReasonText != null && aiReasonText.isNotEmpty) {
              reasons.add("• Văn bản: $aiReasonText");
            }

            if (aiReasonImage != null && aiReasonImage.isNotEmpty) {
              reasons.add("• Hình ảnh: $aiReasonImage");
            }

            if (reasons.isNotEmpty) {
              displayReason = reasons.join("\n");
            } else {
              // Fallback old aiReason
              displayReason = data['aiReason'] ?? 'Nội dung không phù hợp.';
            }

            avoidPrint("DEBUG - Post $postId status updated: $status");

            // if status changed to 'processed', stop listening
            if (status != 'processing') {
              // Cancel the subscription to avoid memory leaks
              await _postSubscription?.cancel();
              _postSubscription = null;

              // Check if widget is still mounted before UI operations
              if (!mounted) return;

              setState(() {
                _isLoading = false; // Stop loading indicator
              });

              if (status == 'active') {
                // AI approved (or AI error -> approved by system_failover) => show success
                if (mounted) {
                  displaySnackBar(
                    "Bài đăng thành công!.",
                    context,
                    SnackBarType.success,
                  );
                }
                removeImage(0); // Clear selected images
                _textController.clear();

                // Navigate to Feed Screen
                if (mounted) {
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
                }
              } else if (status == 'rejected') {
                // Post was rejected, now fetch the scores from violation_logs
                try {
                  final violationLogs = await FirebaseFirestore.instance
                      .collection('violation_logs')
                      .where('targetId', isEqualTo: postId)
                      .orderBy('createdAt', descending: true)
                      .limit(1)
                      .get();

                  double? textScore;
                  double? imageScore;

                  if (violationLogs.docs.isNotEmpty) {
                    final data = violationLogs.docs.first.data();
                    textScore = data['textScore'] as double?;
                    imageScore = data['imageScore'] as double?;

                    // Show rejection dialog with detailed information
                    if (mounted) {
                      RejectionDialog.show(
                        context,
                        title: 'Bài viết bị từ chối',
                        description:
                            'Hệ thống AI đã phát hiện nội dung không phù hợp:',
                        reason:
                            displayReason ?? 'Vui lòng kiểm tra lại nội dung.',
                        textScore: textScore,
                        imageScore: imageScore,
                      );
                    }
                  }
                } catch (e) {
                  // Fallback if fetching log fails
                  if (mounted) {
                    RejectionDialog.show(
                      context,
                      title: 'Bài viết bị từ chối',
                      description:
                          'Hệ thống AI đã phát hiện nội dung không phù hợp:',
                      reason:
                          displayReason ?? 'Vui lòng kiểm tra lại nội dung.',
                    );
                  }
                  avoidPrint("DEBUG - Error fetching violation logs: $e");
                }
                avoidPrint("DEBUG - Post $postId was rejected: $displayReason");
              } else {
                if (mounted) {
                  displaySnackBar(
                    "Bài đăng của bạn có trạng thái không xác định, vui lòng thử lại sau.",
                    context,
                    SnackBarType.error,
                  );
                }
                avoidPrint("DEBUG - Post $postId has unknown status: $status");
              }
            }
          },
          onError: (error) {
            avoidPrint("DEBUG - Post listener error: $error");
            _postSubscription?.cancel();
            _postSubscription = null;

            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              displaySnackBar(
                "Có lỗi xảy ra khi theo dõi trạng thái bài đăng",
                context,
                SnackBarType.error,
              );
            }
          },
        );

    // Safe timeout: If the AI doesn't respond after 10 seconds (network lag, server down)
    // Then stop listening and return to the Feed (to prevent the user's computer from freezing indefinitely)
    Future.delayed(const Duration(seconds: 10), () async {
      // Only process if the subscription has not been canceled (it is still loading).
      if (_postSubscription != null && mounted) {
        await _postSubscription?.cancel();
        _postSubscription = null;

        if (mounted) {
          setState(() {
            _isLoading = false; // Stop loading indicator
          });

          // Navigate back to feed screen after moderation (timeout)
          // Cloud Function will activate automatically after 5 seconds.
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
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _images = [];
    _postSubscription?.cancel(); // Cancel subscription on dispose
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // final User user = Provider.of<UserProvider>(context).getUser;
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUserrOrNull; // safer getter (see below)
    if (user == null) {
      return customCircularProgressIndicator();
    }

    // Check if user has a profile photo
    final hasProfilePhoto = user.photoUrl.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        leading: width > webScreenSize
            ? null
            : IconButton(
                onPressed: () {
                  removeImage(0);
                  // Navigate to the feed screen
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
                  Text('Tạo bài đăng'),
                  const Spacer(),
                  CustomButton(
                    onPressed:
                        hasProfilePhoto // Disable if no photo
                        ? () => postImage(
                            user.uid,
                            user.displayName,
                            user.photoUrl,
                          )
                        : () {}, // Empty function instead of null
                    child: const Text(
                      'Đăng bài',
                      style: TextStyle(
                        color: onPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Spacer(), // Push title to center
                ],
              )
            : const Text('Tạo bài đăng'),
        centerTitle: width > webScreenSize ? true : false,
        actions: width > webScreenSize
            ? null
            : [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: CustomButton(
                    onPressed:
                        hasProfilePhoto // Disable if no photo
                        ? () => postImage(
                            user.uid,
                            user.displayName,
                            user.photoUrl,
                          )
                        : () {}, // Empty function instead of null
                    child: const Text(
                      'Đăng bài',
                      style: TextStyle(
                        color: onPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
              // Check Loading
              if (_isLoading) customLinearProgressIndicator(),

              // 2. Responsive layout
              if (width <= webScreenSize) const Divider(color: secondaryColor),
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
                    cursorColor: appPrimaryColor,
                  ),
                ),
              ),
              const Divider(color: secondaryColor),
              // show the selected image preview
              _images.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          CustomButton(
                            backgroundColor: width > webScreenSize
                                ? webBackgroundColor
                                : mobileBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            overlayColor: appPrimaryColor,
                            hasBorder: true,
                            onPressed: () {
                              _selectImage();
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.image_outlined,
                                  color: primaryTextColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Ảnh',
                                  style: TextStyle(color: primaryTextColor),
                                ),
                              ],
                            ),
                          ),
                          CustomButton(
                            backgroundColor: width > webScreenSize
                                ? webBackgroundColor
                                : mobileBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            overlayColor: appPrimaryColor,
                            hasBorder: true,
                            onPressed: () {},
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.video_camera_back_outlined,
                                  color: primaryTextColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Video',
                                  style: TextStyle(color: primaryTextColor),
                                ),
                              ],
                            ),
                          ),
                          CustomButton(
                            backgroundColor: width > webScreenSize
                                ? webBackgroundColor
                                : mobileBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            overlayColor: appPrimaryColor,
                            hasBorder: true,
                            onPressed: () {},
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.file_open_outlined,
                                  color: primaryTextColor,
                                ),
                                Text(
                                  'Tài liệu',
                                  style: TextStyle(color: primaryTextColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Display the quantity with a warning color if the limit is nearly reached
                              Text(
                                '${_images.length}/$maxTotalImages ảnh đã chọn',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _images.length >= maxTotalImages
                                      ? errorBackgroundColor
                                      : secondaryColor,
                                ),
                              ),
                              CustomButton(
                                backgroundColor:
                                    _images.length >= maxTotalImages
                                    ? secondaryColor
                                    : appPrimaryColor,
                                borderRadius: BorderRadius.circular(8),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                onPressed: _images.length >= maxTotalImages
                                    ? () {}
                                    : () {
                                        _selectImage();
                                      },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _images.length >= maxTotalImages
                                        ? SizedBox.shrink()
                                        : Icon(
                                            Icons.add,
                                            color: onPrimaryColor,
                                            size: 16,
                                          ),
                                    SizedBox(width: 4),
                                    Text(
                                      _images.length >= maxTotalImages
                                          ? 'Đã đủ'
                                          : 'Thêm ảnh',
                                      style: TextStyle(
                                        color: onPrimaryColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Image Preview (can scroll)
                        Container(
                          height: 220,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Stack(
                            children: [
                              ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context)
                                    .copyWith(
                                      dragDevices: {
                                        PointerDeviceKind.touch,
                                        PointerDeviceKind
                                            .mouse, // Enable mouse drag
                                      },
                                      scrollbars:
                                          width >
                                          webScreenSize, // Show scrollbar on Web
                                    ),
                                child: ListView.builder(
                                  controller: _scrollController,
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  physics: const ClampingScrollPhysics(),
                                  itemCount: _images.length,
                                  itemBuilder: (context, index) {
                                    return Stack(
                                      children: [
                                        // Image Container
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.memory(
                                              _images[index],
                                              fit: BoxFit.cover,
                                              width: 200,
                                              height: 200,
                                            ),
                                          ),
                                        ),

                                        // Remove button
                                        Positioned(
                                          top: 4,
                                          left: 12,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: onPrimaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                color: secondaryColor,
                                              ),
                                              onPressed: () {
                                                removeImage(index);
                                              },
                                            ),
                                          ),
                                        ),

                                        // Display image number
                                        Positioned(
                                          bottom: 8,
                                          left: 16,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: onPrimaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${index + 1}/${_images.length}',
                                              style: const TextStyle(
                                                color: secondaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),

                              // Scroll hint indicator (chỉ hiện trên web khi có > 2 ảnh)
                              if (_images.length > 2 &&
                                  width > webScreenSize) ...[
                                // Left scroll button
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 40,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerRight,
                                        end: Alignment.centerLeft,
                                        colors: [
                                          Colors.transparent,
                                          mobileBackgroundColor.withValues(
                                            alpha: 0.7,
                                          ),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.chevron_left,
                                          color: secondaryColor,
                                          size: 24,
                                        ),
                                        onPressed: () {
                                          _scrollController.animateTo(
                                            _scrollController.offset - 200,
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),

                                // Right scroll button
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 40,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.transparent,
                                          mobileBackgroundColor.withValues(
                                            alpha: 0.7,
                                          ),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.chevron_right,
                                          color: secondaryColor,
                                          size: 24,
                                        ),
                                        onPressed: () {
                                          _scrollController.animateTo(
                                            _scrollController.offset + 200,
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              // Mobile gradient hint (chỉ hiện khi có > 2 ảnh và không phải web)
                              if (_images.length > 2 && width <= webScreenSize)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 40,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.transparent,
                                          mobileBackgroundColor.withValues(
                                            alpha: 0.7,
                                          ),
                                        ],
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.chevron_right,
                                        color: secondaryColor,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

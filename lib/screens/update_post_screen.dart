import 'dart:typed_data';
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

class UpdatePostScreen extends StatefulWidget {
  final snap;
  const UpdatePostScreen({super.key, required this.snap});

  @override
  State<UpdatePostScreen> createState() => _UpdatePostScreenState();
}

class _UpdatePostScreenState extends State<UpdatePostScreen> {
  var _image;
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  bool _isReshare = false;

  @override
  void initState() {
    super.initState();
    final postData = widget.snap;
    // Initialize text controller with existing post text
    _textController.text = postData['postText'];
    // Initialize _image with existing post URL
    _image = postData['postUrl'];

    // Check if the post is a reshare
    _isReshare = postData['originalPostId'] != null;
  }

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
                    _image = file;
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
                  Uint8List? file = await pickImage(ImageSource.gallery);
                  if (!mounted) return;
                  if (file == null) {
                    if (scaffoldContext.mounted) {
                      displaySnackBar(
                        'Không thể chọn ảnh từ thư viện',
                        scaffoldContext,
                        SnackBarType.error,
                      );
                    }
                    return;
                  }
                  setState(() {
                    _image = file;
                  });
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

    setState(() {
      _isLoading = true;
    });
    try {
      // For reshared posts, only update the text (not the image)
      if (_isReshare) {
        String res = await FirestoreMethod().updateResharePost(
          postId,
          _textController.text.trim(),
        );
        if (!mounted) return; // guard context after async

        if (res == 'success') {
          setState(() {
            _isLoading = false;
          });
          displaySnackBar(
            'Cập nhật bài đăng thành công!',
            context,
            SnackBarType.success,
          );
          clearImage();
          _textController.clear();
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
        } else {
          setState(() {
            _isLoading = false;
          });
          displaySnackBar(
            'Có lỗi xảy ra, vui lòng thử lại sau.',
            context,
            SnackBarType.error,
          );
        }
      } else {
        // For regular posts, update both text and image

        // Determine if we have a new image (Uint8List) or existing URL (String)
        Uint8List? fileToUpload;
        String? existingUrl;

        if (_image is Uint8List) {
          // User selected a new image
          fileToUpload = _image;
          existingUrl = widget.snap['postUrl']; // Pass the old URL to delete it
        } else if (_image is String) {
          // User kept the existing image
          fileToUpload = null;
          existingUrl = null;
        } else {
          // No image at all
          fileToUpload = null;
          existingUrl = widget.snap['postUrl']; // Delete existing image
        }

        // Add debug logging
        avoidPrint("DEBUG - Updating post:");
        avoidPrint(
          "  fileToUpload: ${fileToUpload != null ? 'New image' : 'null'}",
        );
        avoidPrint("  existingUrl: $existingUrl");
        avoidPrint("  _image type: ${_image.runtimeType}");

        // Update post's text and image
        String res = await FirestoreMethod().updatePost(
          postId,
          _textController.text.trim(),
          fileToUpload,
          existingUrl,
        );

        if (!mounted) return; // guard context after async

        if (res == 'success') {
          setState(() {
            _isLoading = false;
          });
          displaySnackBar(
            'Cập nhật bài đăng thành công!',
            context,
            SnackBarType.success,
          );
          clearImage();
          _textController.clear();
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
        } else {
          setState(() {
            _isLoading = false;
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
      if (!mounted) return; // guard context after async
      setState(() {
        _isLoading = false;
      });
      avoidPrint("Exception in updatePost: $e");
      displaySnackBar(
        'Có lỗi xảy ra khi cập nhật bài đăng',
        context,
        SnackBarType.error,
      );
    }
  }

  void clearImage() {
    setState(() {
      _image = null;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _textController.dispose();
    _image = null;
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
                  ? customLinearProgressIndicator()
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
                Center(
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      if (_isLoading)
                        customCircularProgressIndicator()
                      else if (_image == null)
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: const Text(
                            'Không có ảnh cho bài đăng',
                            style: TextStyle(color: primaryTextColor),
                          ),
                        )
                      else if (_image is Uint8List)
                        Image.memory(
                          _image as Uint8List,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        )
                      else if (_image is String)
                        Image.network(
                          _image as String,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: const Text(
                              'Không thể tải ảnh',
                              style: TextStyle(color: primaryTextColor),
                            ),
                          ),
                        ),
                      if (_image != null && !_isLoading)
                        IconButton(
                          icon: const Icon(Icons.edit, color: secondaryColor),
                          onPressed: () {
                            _selectImage();
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to show original post preview
  Widget _buildOriginalPostPreview(Map<String, dynamic> postData) {
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
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundImage: NetworkImage(
                  postData['originalProfImage'] ?? '',
                ),
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
          if (postData['originalPostText'] != null &&
              postData['originalPostText'].isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              postData['originalPostText'],
              style: const TextStyle(color: primaryTextColor, fontSize: 14),
            ),
          ],
          if (postData['postUrl'] != null &&
              postData['postUrl'].isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                postData['postUrl'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Text(
                  'Không thể tải ảnh gốc',
                  style: TextStyle(color: primaryTextColor),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Bạn không thể chỉnh sửa nội dung gốc',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: primaryTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

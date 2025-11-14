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

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  Uint8List? _image;
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  Future<void> _selectImage(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: mobileBackgroundColor,
          title: const Text('Chọn ảnh cho bài đăng'),
          children: [
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Chụp ảnh'),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  Uint8List? file = await pickImage(ImageSource.camera);
                  if (!mounted) return;
                  if (file == null) {
                    displaySnackBar(
                      'Không thể chụp ảnh',
                      context,
                      SnackBarType.error,
                    );
                    return;
                  }
                  ;
                  setState(() {
                    _image = file;
                  });
                } catch (e) {
                  if (!mounted) return;
                  displaySnackBar(
                    'Có lỗi xảy ra khi chụp ảnh',
                    context,
                    SnackBarType.error,
                  );
                  avoidPrint(e.toString());
                }
              },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Chọn ảnh từ thư viện'),
              onPressed: () async {
                try {
                  Navigator.of(context).pop();
                  Uint8List? file = await pickImage(ImageSource.gallery);
                  if (!mounted) return;
                  if (file == null) {
                    displaySnackBar(
                      'Không thể chọn ảnh từ thư viện',
                      context,
                      SnackBarType.error,
                    );
                    return;
                  }
                  ;
                  setState(() {
                    _image = file;
                  });
                } catch (e) {
                  if (!mounted) return;
                  displaySnackBar(
                    'Có lỗi xảy ra khi chọn ảnh',
                    context,
                    SnackBarType.error,
                  );
                  avoidPrint(e.toString());
                }
              },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Hủy'),
              onPressed: () async {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void clearImage() {
    setState(() {
      _image = null;
    });
  }

  void postImage(String uid, String displayName, String profImage) async {
    // Validate inputs
    if (_textController.text.isEmpty) {
      displaySnackBar(
        'Vui lòng nhập mô tả cho bài đăng',
        context,
        SnackBarType.error,
      );
      return;
    }

    if (_image == null) {
      displaySnackBar(
        'Vui lòng chọn ảnh để đăng bài',
        context,
        SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      // upload to storage and db
      String res = await FirestoreMethod().uploadPost(
        _textController.text.trim(),
        _image!,
        uid,
        displayName,
        profImage,
      );

      if (!mounted) return; // guard context after async

      if (res == "success") {
        setState(() {
          _isLoading = false;
        });
        displaySnackBar('Đăng bài thành công!', context, SnackBarType.success);
        clearImage();
        _textController.clear();
        // Navigate to the feed screen
      } else {
        setState(() {
          _isLoading = false;
        });
        displaySnackBar(
          "Có lỗi xảy ra, vui lòng thử lại sau.",
          context,
          SnackBarType.error,
        );
        avoidPrint(res);
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

  @override
  void dispose() {
    super.dispose();
    _textController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // final User user = Provider.of<UserProvider>(context).getUser;
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUserrOrNull; // safer getter (see below)
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        leading: width > webScreenSize
            ? null
            : IconButton(
                onPressed: () {
                  clearImage();
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
                  TextButton(
                    onPressed: () =>
                        postImage(user.uid, user.displayName, user.photoUrl),
                    child: const Text(
                      'Đăng bài',
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
            : const Text('Tạo bài đăng'),
        centerTitle: width > webScreenSize ? true : false,
        actions: width > webScreenSize
            ? null
            : [
                TextButton(
                  onPressed: () =>
                      postImage(user.uid, user.displayName, user.photoUrl),
                  child: const Text(
                    'Đăng bài',
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
                  ? const LinearProgressIndicator(
                      backgroundColor: secondaryColor,
                      color: appPrimaryColor,
                    )
                  : Padding(padding: EdgeInsets.only(top: 0)),
              ?width > webScreenSize
                  ? null
                  : const Divider(color: secondaryColor),
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
                  ),
                ),
              ),
              const Divider(color: secondaryColor),
              // show the selected image preview
              _image == null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        customTextButton(
                          icon: Icons.photo_library,
                          label: 'Ảnh',
                          onPressed: () => _selectImage(context),
                        ),
                        customTextButton(
                          icon: Icons.videocam,
                          label: 'Video',
                          onPressed: () {},
                        ),
                        customTextButton(
                          icon: Icons.file_copy,
                          label: 'Tài liệu',
                          onPressed: () {},
                        ),
                      ],
                    )
                  : Center(
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Image.memory(
                            _image!,
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.cancel,
                              color: secondaryColor,
                            ),
                            onPressed: clearImage,
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

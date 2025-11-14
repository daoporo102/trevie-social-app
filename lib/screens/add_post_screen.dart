import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/firestore_method.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/utils.dart';

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
          title: const Text('Tạo bài đăng'),
          children: [
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Chụp ảnh'),
              onPressed: () async {
                Navigator.of(context).pop();
<<<<<<< Updated upstream
                Uint8List? file = await pickImage(ImageSource.camera);
                if (!mounted) return;
                setState(() {
                  _image = file;
                });
=======
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
>>>>>>> Stashed changes
              },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Chọn ảnh từ thư viện'),
              onPressed: () async {
<<<<<<< Updated upstream
                Navigator.of(context).pop();
                Uint8List? file = await pickImage(ImageSource.gallery);
                if (!mounted) return;
                setState(() {
                  _image = file;
                });
=======
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
>>>>>>> Stashed changes
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
      if (res == "success") {
        setState(() {
          _isLoading = false;
        });
        showSnackBar('Đăng bài thành công!', context);
        clearImage();
<<<<<<< Updated upstream
=======
        _textController.clear();
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
>>>>>>> Stashed changes
      } else {
        setState(() {
          _isLoading = false;
        });
        showSnackBar(res, context);
      }
    } catch (e) {
      showSnackBar(e.toString(), context);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _textController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final User user = Provider.of<UserProvider>(context).getUser;
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUserrOrNull; // safer getter (see below)
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return _image == null
        ? Scaffold(
            backgroundColor: mobileBackgroundColor,
            body: Center(
              child: IconButton(
                onPressed: () => _selectImage(context),
                icon: Icon(Icons.upload),
              ),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              leading: IconButton(
                onPressed: () => clearImage(),
                icon: const Icon(Icons.arrow_back),
              ),
              title: const Text('Tạo bài đăng'),
              centerTitle: false,
              actions: [
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
            body: Column(
              children: [
                _isLoading
                    ? const LinearProgressIndicator(
                        backgroundColor: secondaryColor,
                        color: appPrimaryColor,
                      )
                    : Padding(padding: EdgeInsets.only(top: 0)),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.45,
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'Viết mô tả của bạn...',
                          border: InputBorder.none,
                        ),
                        maxLines: 8,
                      ),
                    ),
                    SizedBox(
                      height: 45,
                      width: 45,
                      child: AspectRatio(
                        aspectRatio: 487 / 451,
                        child: Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              fit: BoxFit.fill,
                              alignment: FractionalOffset.topCenter,
                              image: MemoryImage(_image!),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
                  ],
                ),
              ],
            ),
          );
  }
}

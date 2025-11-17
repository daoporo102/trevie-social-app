import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/auth_methods.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/custom_inkwell.dart';
import 'package:social_media_app/widgets/custom_snack_bar.dart';
import 'package:social_media_app/widgets/text_field_input.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  Map<String, dynamic> userData = {};
  bool _isLoading = false;
  final TextEditingController _displayNameController = TextEditingController();
  var _image;
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    //fetch user data and set to userData map
    _fetchUserData();
  }

  void _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await AuthMethods().getUserDetails();
      if (!mounted) return;
      setState(() {
        userData = {
          'uid': user.uid,
          'displayName': user.displayName,
          'email': user.email,
          'photoUrl': user.photoUrl,
          'bio': user.bio,
        };
        _displayNameController.text = user.displayName;
        _bioController.text = user.bio;
        _image = user.photoUrl; // Initialize with existing photo URL
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      displaySnackBar(
        'Lỗi tải dữ liệu người dùng: $e',
        context,
        SnackBarType.error,
      );
      avoidPrint("Error fetching user data: $e");
    }
  }

  Future<void> selectImage() async {
    try {
      final Uint8List? im = await pickImage(ImageSource.gallery);
      if (!mounted) return;
      if (im == null) {
        displaySnackBar(
          'Không có hình ảnh nào được chọn',
          context,
          SnackBarType.error,
        );
        return;
      }
      setState(() {
        _image = im;
      });
    } catch (e) {
      if (!mounted) return;
      displaySnackBar('Lỗi chọn hình ảnh: $e', context, SnackBarType.error);
    }
  }

  Future<void> updateUserProfile(String uid) async {
    // Validate inputs
    if (_displayNameController.text.isEmpty) {
      displaySnackBar(
        'Tên hiển thị không được để trống',
        context,
        SnackBarType.error,
      );
      return;
    }

    if (_bioController.text.length > 150) {
      displaySnackBar(
        'Tiểu sử không được vượt quá 150 ký tự',
        context,
        SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      // Determine if we have a new image (Uint8List) or existing URL (String)
      Uint8List? fileToUpload;
      String? existingUrl;

      if (_image is Uint8List) {
        // User selected a new image
        fileToUpload = _image;
        existingUrl = userData['photoUrl']; // Pass the old URL to delete it
      } else if (_image is String) {
        // User kept the existing image
        existingUrl = null;
        fileToUpload = null;
      }

      // Update user profile
      String res = await AuthMethods().updateUserProfile(
        uid,
        _displayNameController.text.trim(),
        fileToUpload,
        existingUrl,
        _bioController.text.trim(),
      );

      if (!mounted) return; // Check if the widget is still mounted

      if (res == 'success') {
        //refresh provider so UI updates immediately
        Provider.of<UserProvider>(context, listen: false).refreshUser();

        if (!mounted) return;

        if(fileToUpload!=null){
          imageCache.clear();
          imageCache.clearLiveImages();
        }

        setState(() {
          _isLoading = false;
        });
        displaySnackBar(
          'Cập nhật hồ sơ thành công',
          context,
          SnackBarType.success,
        );
        clearImage();
        _displayNameController.clear();
        _bioController.clear();
        // Navigate back to the previous screen
        Navigator.pop(context);
      } else {
        setState(() {
          _isLoading = false;
        });
        displaySnackBar(
          "Có lỗi xảy ra, vui lòng thử lại sau.",
          context,
          SnackBarType.error,
        );
        avoidPrint("Error updating profile: $res");
      }
    } catch (e) {
      if (!mounted) return; // Check if the widget is still mounted
      setState(() {
        _isLoading = false;
      });
      displaySnackBar(
        "Có lỗi xảy ra, vui lòng thử lại sau.",
        context,
        SnackBarType.error,
      );
      avoidPrint("Exception updating profile: $e");
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
    _displayNameController.dispose();
    _bioController.dispose();
    _image = null;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: Text(
          "Chỉnh sửa hồ sơ",
          style: TextStyle(color: primaryTextColor),
        ),
        centerTitle: false,
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: customLinearProgressIndicator(),
              )
            : null,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Container(
          padding: width > webScreenSize
              ? EdgeInsets.symmetric(horizontal: width / 3)
              : const EdgeInsets.symmetric(horizontal: 32),
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Stack(
                children: [
                  if (_isLoading)
                    customCircularProgressIndicator()
                  else if (_image == null)
                    CircleAvatar(
                      radius: 64,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 64,
                        color: primaryTextColor,
                      ),
                    )
                  else if (_image is Uint8List)
                    CircleAvatar(
                      radius: 64,
                      backgroundImage: MemoryImage(_image),
                    )
                  else if (_image is String)
                    CircleAvatar(
                      radius: 64,
                      backgroundImage: NetworkImage(_image),
                    ),
                  Positioned(
                    bottom: -10,
                    left: 80,
                    child: IconButton(
                      onPressed: _isLoading ? null : selectImage,
                      icon: const Icon(Icons.edit),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFieldInput(
                textEditingController: _displayNameController,
                hintText: 'Vui lòng nhập tên hiển thị',
                textInputType: TextInputType.text,
                prefixIcon: Icons.person_outline,
                labelText: 'Tên hiển thị',
              ),
              const SizedBox(height: 24),
              TextFieldInput(
                textEditingController: _bioController,
                hintText: 'Vui lòng nhập tiểu sử',
                textInputType: TextInputType.text,
                prefixIcon: Icons.person_outline,
                labelText: 'Tiểu sử',
              ),
              const SizedBox(height: 24),
              CustomInkwell(
                title: 'Lưu',
                onTap: () => updateUserProfile(userData['uid']),
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

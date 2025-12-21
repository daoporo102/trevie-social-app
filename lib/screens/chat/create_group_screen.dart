import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/models/user.dart' as model;
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/chat_method.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/custom_button.dart';
import 'package:social_media_app/widgets/custom_snack_bar.dart';
import 'package:social_media_app/widgets/text_field_input.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  // Save selected user IDs
  List<String> selectedUserIds = [];
  bool _isLoading = false;
  String currentUid = FirebaseAuth.instance.currentUser!.uid;
  Uint8List? _groupIcon;

  void createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      displaySnackBar('Vui lòng nhập tên nhóm.', context, SnackBarType.error);
      return;
    }
    if (selectedUserIds.isEmpty) {
      displaySnackBar(
        'Vui lòng chọn ít nhất một thành viên.',
        context,
        SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Create group logic here
    String res = await ChatMethod().createGroup(
      groupName: _groupNameController.text.trim(),
      creatorId: currentUid,
      memberIds: selectedUserIds,
      groupIcon: _groupIcon,
    );

    setState(() {
      _isLoading = false;
    });

    if (res == "success") {
      if (!mounted) return;
      Navigator.pop(context); // Close the create group screen
      displaySnackBar('Tạo nhóm thành công!', context, SnackBarType.success);
    } else {
      if (!mounted) return;
      avoidPrint("Error creating group: $res");
      displaySnackBar(
        'Tạo nhóm thất bại, vui lòng thử lại.',
        context,
        SnackBarType.error,
      );
    }
  }

  // Toggle user selection
  void toggleUserSelection(String userId) {
    setState(() {
      if (selectedUserIds.contains(userId)) {
        selectedUserIds.remove(userId);
      } else {
        selectedUserIds.add(userId);
      }
    });
  }

  // Select image for group icon
  Future<void> _selectImage() async {
    final Uint8List? im = await pickImage(ImageSource.gallery);
    if (im != null) {
      setState(() {
        _groupIcon = im;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final model.User? currentUser = Provider.of<UserProvider>(
      context,
    ).getUserrOrNull;
    final width = MediaQuery.of(context).size.width;

    if (currentUser == null) {
      return Center(child: customCircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo nhóm mới'),
        backgroundColor: width > webScreenSize
            ? webBackgroundColor
            : mobileBackgroundColor,
        actions: [
          CustomButton(
            onPressed: createGroup,
            child: _isLoading
                ? customCircularProgressIndicator()
                : Text(
                    'Tạo',
                    style: TextStyle(
                      color: onPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: customCircularProgressIndicator())
          : Column(
              children: [
                // Group Icon and Name Input
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundImage: _groupIcon != null
                                ? MemoryImage(_groupIcon!)
                                : null,
                            child: _groupIcon == null
                                ? const Icon(
                                    Icons.group,
                                    size: 32,
                                    color: onPrimaryColor,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: -10,
                            right: -10,
                            child: IconButton(
                              icon: const Icon(Icons.add_a_photo),
                              onPressed: _selectImage,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFieldInput(
                          textEditingController: _groupNameController,
                          hintText: 'Nhập tên nhóm',
                          textInputType: TextInputType.text,
                          labelText: 'Tên nhóm', prefixIcon: Icons.group,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Chọn thành viên:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // User Selection List (get from collection users)
                // need to get from 'following' collection or 'followers' collection
                Expanded(
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: customCircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Lỗi: ${snapshot.error}'));
                      }
                      final users = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          var userData = user.data() as Map<String, dynamic>;
                          String uid = userData['uid'];

                          // FILTER LOGIC: Only display if the uid is in its following list
                          // And do not display itself
                          bool isFollowing = currentUser.following.contains(
                            uid,
                          );

                          if (!isFollowing || uid == currentUid) {
                            return const SizedBox.shrink(); // Skip this user
                          }

                          bool isSelected = selectedUserIds.contains(uid);

                          return CheckboxListTile(
                            title: Text(user['displayName']),
                            value: isSelected,
                            onChanged: (value) =>
                                toggleUserSelection(user['uid']),
                            secondary: CircleAvatar(
                              backgroundImage: NetworkImage(user['photoUrl']),
                            ),
                            activeColor: appPrimaryColor,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

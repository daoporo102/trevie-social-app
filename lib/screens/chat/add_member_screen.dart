import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/models/user.dart' as model;
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/chat_method.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/custom_button.dart';
import 'package:social_media_app/widgets/custom_snack_bar.dart';

class AddMemberScreen extends StatefulWidget {
  final String chatRoomId;
  const AddMemberScreen({super.key, required this.chatRoomId});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final List<String> _selectedUserIds = [];
  bool _isLoading = true;
  List<String> _currentMemberIds = [];

  @override
  void initState() {
    super.initState();
    _fetchCurrentMembers();
  }

  Future<void> _fetchCurrentMembers() async {
    try {
      DocumentSnapshot chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .get();
      if (chatDoc.exists) {
        setState(() {
          _currentMemberIds = List<String>.from(chatDoc['users'] ?? []);
        });
      }
    } catch (e) {
      if(mounted){
        displaySnackBar(
        'Lỗi tải thành viên hiện tại: $e',
        context,
        SnackBarType.error,
      );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  void _addMembersToGroup() async {
    if (_selectedUserIds.isEmpty) {
      displaySnackBar(
        'Vui lòng chọn ít nhất một thành viên để thêm.',
        context,
        SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String res = await ChatMethod().addUserToGroup(
      widget.chatRoomId,
      _selectedUserIds,
    );

    if (mounted) {
      if (res == 'success') {
        displaySnackBar(
          'Thêm thành viên thành công!',
          context,
          SnackBarType.success,
        );
        Navigator.of(context).pop();
      } else {
        displaySnackBar('Lỗi: $res', context, SnackBarType.error);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final model.User? currentUser = Provider.of<UserProvider>(
      context,
    ).getUserrOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm thành viên'),
        actions: [
          CustomButton(
            onPressed: _addMembersToGroup,
            child: const Text('Thêm',style:TextStyle(color:onPrimaryColor)),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: customCircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where(
                    'uid',
                    whereIn: currentUser?.following.isEmpty == false
                        ? currentUser?.following
                        : [' '],
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: customCircularProgressIndicator());
                }

                final potentialMembers = snapshot.data!.docs
                    .where((doc) => !_currentMemberIds.contains(doc.id))
                    .toList();

                if (potentialMembers.isEmpty) {
                  return const Center(
                    child: Text('Tất cả bạn bè của bạn đã ở trong nhóm.'),
                  );
                }

                return ListView.builder(
                  itemCount: potentialMembers.length,
                  itemBuilder: (context, index) {
                    final userData =
                        potentialMembers[index].data() as Map<String, dynamic>;
                    final userId = userData['uid'];
                    final isSelected = _selectedUserIds.contains(userId);

                    return CheckboxListTile(
                      secondary: CircleAvatar(
                        backgroundImage: NetworkImage(userData['photoUrl']),
                      ),
                      title: Text(userData['displayName']),
                      value: isSelected,
                      onChanged: (bool? value) {
                        _toggleUserSelection(userId);
                      },
                      activeColor: appPrimaryColor,
                    );
                  },
                );
              },
            ),
    );
  }
}

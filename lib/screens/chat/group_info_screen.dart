import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/resources/chat_method.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/screens/profile_screen.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/custom_snack_bar.dart';

class GroupInfoScreen extends StatelessWidget {
  final String chatRoomId;

  const GroupInfoScreen({super.key, required this.chatRoomId});

  Future<void> _removeUser(
    BuildContext context,
    String userIdToRemove,
    String userDisplayName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: mobileBackgroundColor,
        title: Text('Xóa thành viên?'),
        content: Text(
          'Bạn có chắc chắn muốn xóa "$userDisplayName" khỏi nhóm?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Xóa',
              style: TextStyle(color: errorBackgroundColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final adminId = FirebaseAuth.instance.currentUser?.uid;
      if (adminId == null) {
        if (context.mounted) {
          displaySnackBar(
            'Không thể xác thực quản trị viên.',
            context,
            SnackBarType.error,
          );
        }
        return;
      }

      String res = await ChatMethod().removeUserFromGroup(
        chatRoomId,
        userIdToRemove,
        adminId,
      );

      if (context.mounted) {
        if (res == 'success') {
          displaySnackBar(
            'Đã xóa thành viên thành công.',
            context,
            SnackBarType.success,
          );
        } else {
          displaySnackBar('Lỗi: $res', context, SnackBarType.error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin nhóm'),
        backgroundColor: width > webScreenSize
            ? webBackgroundColor
            : mobileBackgroundColor,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(chatRoomId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: customCircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Không tìm thấy thông tin nhóm.'));
          }

          final groupData = snapshot.data!.data() as Map<String, dynamic>;
          final List<String> memberIds = List<String>.from(
            groupData['users'] ?? [],
          );

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Group Icon
                CircleAvatar(
                  radius: 64,
                  backgroundImage:
                      (groupData['groupIconUrl'] != null &&
                          groupData['groupIconUrl'].isNotEmpty)
                      ? NetworkImage(groupData['groupIconUrl'])
                      : null,
                  child:
                      (groupData['groupIconUrl'] == null ||
                          groupData['groupIconUrl'].isEmpty)
                      ? const Icon(Icons.group, size: 64, color: onPrimaryColor)
                      : null,
                ),
                const SizedBox(height: 16),
                // Group Name
                Text(
                  groupData['groupName'] ?? 'Nhóm chưa có tên',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${memberIds.length} thành viên',
                  style: const TextStyle(fontSize: 16, color: secondaryColor),
                ),
                const Divider(height: 32),
                // Member List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: memberIds.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(memberIds[index])
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: secondaryColor.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            title: Container(
                              height: 16,
                              width: 100,
                              color: secondaryColor.withValues(alpha: 0.5),
                            ),
                          );
                        }
                        final userData =
                            userSnapshot.data!.data() as Map<String, dynamic>;
                        final bool isViewerAdmin =
                            groupData['adminId'] ==
                            FirebaseAuth.instance.currentUser?.uid;
                        final bool isThisMemberAdmin =
                            groupData['adminId'] == userData['uid'];

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                (userData['photoUrl'] != null &&
                                    userData['photoUrl'].isNotEmpty)
                                ? NetworkImage(userData['photoUrl'])
                                : null,
                            child:
                                (userData['photoUrl'] == null ||
                                    userData['photoUrl'].isEmpty)
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                            userData['displayName'] ?? 'Người dùng không tên',
                          ),
                          trailing: isThisMemberAdmin
                              ? const Text(
                                  'Quản trị viên',
                                  style: TextStyle(color: appPrimaryColor),
                                )
                              : (isViewerAdmin
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _removeUser(
                                          context,
                                          userData['uid'],
                                          userData['displayName'],
                                        ),
                                      )
                                    : null),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProfileScreen(uid: userData['uid']),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

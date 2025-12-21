import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/models/user.dart' as model;
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/chat_method.dart';
import 'package:social_media_app/screens/chat/add_member_screen.dart';
import 'package:social_media_app/screens/chat/group_info_screen.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/custom_button.dart';
import 'package:social_media_app/widgets/custom_snack_bar.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String? receiverId;
  final String name;
  final String photoUrl;
  final bool isGroup;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    this.receiverId,
    required this.name,
    required this.photoUrl,
    this.isGroup = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  // Auto-scroll to the bottom when a new message is sent/received
  final ScrollController _scrollController = ScrollController();

  void sendMessage(model.User sender) async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    String res = await ChatMethod().sendMessage(
      senderId: sender.uid,
      senderDisplayName: sender.displayName,
      senderPhotoUrl: sender.photoUrl,
      text: messageText,
      groupId: widget.isGroup ? widget.chatRoomId : null,
      receiverId: widget.isGroup ? null : widget.receiverId,
    );

    if (res == "success") {
      _messageController.clear();
      //
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 50,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } else {
      if (mounted) {
        avoidPrint("Error sending message: $res");
        displaySnackBar(
          "Đã xảy ra lỗi khi gửi tin nhắn, vui lòng thử lại sau.",
          context,
          SnackBarType.error,
        );
      }
    }
  }

  Future<void> _changeGroupIcon() async {
    final Uint8List? file = await pickImage(ImageSource.gallery);
    if (file == null) return;

    if (mounted) {
      displaySnackBar("Đang cập nhật ảnh nhóm...", context, SnackBarType.info);
    }

    String res = await ChatMethod().updateGroupIcon(
      widget.chatRoomId,
      file,
      widget.photoUrl,
    );

    if (mounted) {
      Navigator.of(context).pop(); // Close the dialog
      if (res == 'success') {
        displaySnackBar(
          "Cập nhật ảnh nhóm thành công!",
          context,
          SnackBarType.success,
        );
        // The UI will update automatically due to the stream in ChatListScreen
      } else {
        avoidPrint("Failed to change group icon: $res");
        displaySnackBar(
          "Lỗi cập nhật ảnh nhóm, vui lòng thử lại sau",
          context,
          SnackBarType.error,
        );
      }
    }
  }

  Future<void> _leaveGroup() async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MediaQuery.of(context).size.width > webScreenSize
            ? webBackgroundColor
            : mobileBackgroundColor,
        title: const Text('Rời khỏi nhóm?'),
        content: const Text(
          'Bạn có chắc chắn muốn rời khỏi cuộc trò chuyện này không?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Hủy',
              style: TextStyle(fontSize: 16, color: primaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Rời khỏi', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;

      final user = Provider.of<UserProvider>(
        context,
        listen: false,
      ).getUserrOrNull;
      if (user == null) return;

      String res = await ChatMethod().leaveGroup(widget.chatRoomId, user.uid);

      if (mounted) {
        if (res == 'success') {
          // Pop until we are back at the root (ChatListScreen)
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          avoidPrint("Failed to leave group: $res");
          displaySnackBar(
            'Đã xảy ra lỗi khi rời nhóm, vui lòng thử lại sau.',
            context,
            SnackBarType.error,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final model.User? user = Provider.of<UserProvider>(context).getUserrOrNull;
    if (user == null) return Center(child: customCircularProgressIndicator());
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: width > webScreenSize
            ? webBackgroundColor
            : mobileBackgroundColor,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: (widget.photoUrl.isNotEmpty)
                  ? NetworkImage(widget.photoUrl)
                  : null,
              radius: width > webScreenSize ? 20 : 16,
              // // If it's a group, use the default icon if there are no photos.
              child: (widget.isGroup && widget.photoUrl.isEmpty)
                  ? Icon(
                      Icons.group,
                      color: onPrimaryColor,
                      size: width > webScreenSize ? 24 : 20,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(widget.name, style: TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          // more button
          CustomButton(
            backgroundColor: width > webScreenSize
                ? webBackgroundColor
                : mobileBackgroundColor,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  backgroundColor: width > webScreenSize
                      ? webBackgroundColor
                      : mobileBackgroundColor,
                  title: const Text('Tùy chọn'),
                  children: [
                    if (widget.isGroup) ...[
                      // VIEW GROUP INFO
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => GroupInfoScreen(
                                chatRoomId: widget.chatRoomId,
                              ),
                            ),
                          );
                        },
                        child: const Text('Xem thông tin nhóm'),
                      ),
                      // CHANGE GROUP ICON (Admin only)
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('chats')
                            .doc(widget.chatRoomId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          final groupData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final isAdmin = groupData['adminId'] == user.uid;

                          if (isAdmin) {
                            return SimpleDialogOption(
                              onPressed: _changeGroupIcon,
                              child: const Text('Thay đổi ảnh nhóm'),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 8),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddMemberScreen(
                                chatRoomId: widget.chatRoomId,
                              ),
                            ),
                          );
                        },
                        child: const Text('Thêm thành viên'),
                      ),
                    ],
                    SimpleDialogOption(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _leaveGroup();
                      },
                      child: const Text('Rời khỏi nhóm'),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Hủy'),
                    ),
                  ],
                ),
              );
            },
            child: const Icon(Icons.more_vert, color: primaryTextColor),
          ),
        ],
      ),
      body: Column(
        children: [
          // LIST MESSAGES
          Expanded(
            child: StreamBuilder(
              stream: ChatMethod().getMessages(widget.chatRoomId),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: customCircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Chưa có tin nhắn.'));
                }

                // Auto-scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData =
                        messages[index].data() as Map<String, dynamic>;
                    final isSentByMe = messageData['senderId'] == user.uid;

                    // Format message time
                    final messageTime =
                        messageData['datePublished'] as Timestamp?;
                    final formattedTime = messageTime != null
                        ? DateFormat('HH:mm', 'vi').format(messageTime.toDate())
                        : '';
                    final senderPhotoUrl =
                        messageData['senderPhotoUrl'] as String? ?? '';
                    final senderDisplayName =
                        messageData['senderDisplayName'] as String? ?? '...';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        mainAxisAlignment: isSentByMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isSentByMe) ...[
                            CircleAvatar(
                              radius: 12,
                              backgroundColor:
                                  Colors.transparent, // Important for SVG
                              child: ClipOval(
                                child: senderPhotoUrl.isEmpty
                                    ? const Icon(Icons.person, size: 24)
                                    : senderPhotoUrl.startsWith('assets/')
                                    ? SvgPicture.asset(
                                        senderPhotoUrl,
                                        fit: BoxFit.contain,
                                      )
                                    : Image.network(
                                        senderPhotoUrl,
                                        fit: BoxFit.cover,
                                        width: 24,
                                        height: 24,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.person,
                                                  size: 24,
                                                ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isSentByMe
                                    ? appPrimaryColor
                                    : secondaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: isSentByMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (!isSentByMe && widget.isGroup) ...[
                                    Text(
                                      senderDisplayName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: appPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  Text(
                                    messageData['text'] ?? '',
                                    style: TextStyle(
                                      color: isSentByMe
                                          ? onPrimaryColor
                                          : primaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formattedTime,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isSentByMe
                                          ? onPrimaryColor.withValues(
                                              alpha: 0.7,
                                            )
                                          : secondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // INPUT FIELD
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: secondaryColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: appPrimaryColor,
                    onPressed: () => sendMessage(user),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

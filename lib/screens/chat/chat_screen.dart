import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/models/user.dart' as model;
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/chat_method.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/custom_snack_bar.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverPhotoUrl;
  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverPhotoUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  // Auto-scroll to the bottom when a new message is sent/received
  final ScrollController _scrollController = ScrollController();

  void sendMessage(String senderUid) async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    String res = await ChatMethod().sendMessage(
      senderId: senderUid,
      receiverId: widget.receiverId,
      text: messageText,
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
              backgroundImage: NetworkImage(widget.receiverPhotoUrl),
              radius: width > webScreenSize ? 20 : 16,
            ),
            const SizedBox(width: 10),
            Text(widget.receiverName, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          // LIST MESSAGES
          Expanded(
            child: StreamBuilder(
              stream: ChatMethod().getMessages(user.uid, widget.receiverId),
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

                    return Align(
                      alignment: isSentByMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
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
                                    ? onPrimaryColor.withValues(alpha: 0.7)
                                    : secondaryColor,
                              ),
                            ),
                          ],
                        ),
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
                    onPressed: () => sendMessage(user.uid),
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

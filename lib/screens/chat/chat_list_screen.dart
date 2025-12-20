import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/models/user.dart' as model;
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/chat_method.dart';
import 'package:social_media_app/screens/chat/chat_screen.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/utils/utils.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
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
        title: const Text('Tin nhắn'),
        // centerTitle: true,
      ),
      body: StreamBuilder(
        stream: ChatMethod().getUserChatRooms(user.uid),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: customCircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Chưa có cuộc trò chuyện nào.'));
          }

          final chatRooms = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoomData =
                  chatRooms[index].data() as Map<String, dynamic>;

              // Extract receiver info
              List users = chatRoomData['users'];
              String receiverId = users.firstWhere(
                (uid) => uid != user.uid,
                orElse: () => '',
              );

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(receiverId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: customCircularProgressIndicator());
                  }
                  if (!userSnapshot.hasData || userSnapshot.data == null) {
                    return Center(child: Text('Không tìm thấy người dùng.'));
                  }

                  var userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;

                  // Format last message time
                  final lastMessageTime =
                      chatRoomData['lastMessageTime'] as Timestamp?;
                  final formattedTime = lastMessageTime != null
                      ? formatTimestamp(lastMessageTime)
                      : '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(userData['photoUrl']),
                    ),
                    title: Text(
                      userData['displayName'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      chatRoomData['lastMessage'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: secondaryColor),
                    ),
                    trailing: Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: secondaryColor,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            receiverId: userData['uid'],
                            receiverName: userData['displayName'],
                            receiverPhotoUrl: userData['photoUrl'],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

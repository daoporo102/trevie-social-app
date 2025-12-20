import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_media_app/models/message.dart';
import 'package:uuid/uuid.dart';

class ChatMethod {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    String type = 'text', // 'text', 'image'
  }) async {
    String res = "Some error occurred";
    try {
      if (text.isNotEmpty) {
        // Create Chat Room ID: Always arrange the uid to ensure that A chats with B in the same way B chats with A.
        // Example: userA_userB
        List<String> ids = [senderId, receiverId];
        ids.sort();
        String chatRoomId = ids.join("_");

        String messageId = const Uuid().v1();
        DateTime now = DateTime.now();

        Message message = Message(
          senderId: senderId,
          receiverId: receiverId,
          text: text,
          type: type,
          datePublished: now,
          messageId: messageId,
        );

        // Store message for sub-collection 'messages'
        await _firestore
            .collection('chats')
            .doc(chatRoomId)
            .collection('messages')
            .doc(messageId)
            .set(message.toJson());

        // Update last message info in chat room document
        await _firestore.collection('chats').doc(chatRoomId).set({
          'users': ids,
          'lastMessage': text,
          'lastMessageSenderId': senderId,
          'lastMessageTime': Timestamp.fromDate(now),
        }, SetOptions(merge: true));

        res = "success";
      } else {
        res = "Vui lòng nhập nội dung tin nhắn";
      }
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  // Get messages stream for a specific chat room (Real-time)
  Stream<QuerySnapshot> getMessages(String senderId, String receiverId) {
    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('datePublished', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserChatRooms(String userUid) {
    return _firestore
        .collection('chats')
        .where('users', arrayContains: userUid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }
}

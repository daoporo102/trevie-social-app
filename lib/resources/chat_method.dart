import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_media_app/models/message.dart';
import 'package:social_media_app/resources/storage_method.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:uuid/uuid.dart';

class ChatMethod {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> sendMessage({
    required String senderId,
    required String senderDisplayName,
    required String senderPhotoUrl,
    required String text,
    String? receiverId, // use for 1-1 chats
    String? groupId, // use for group chats
    String type = 'text', // 'text', 'image'
  }) async {
    String res = "Some error occurred";
    try {
      if (text.isNotEmpty) {
        String chatRoomId;

        // LOGIC to determine chatRoomId
        if (groupId != null) {
          // Group chat -> use provided groupId
          chatRoomId = groupId;
        } else if (receiverId != null) {
          // 1-1 chat -> create chatRoomId based on user IDs
          List<String> ids = [senderId, receiverId];
          ids.sort();
          chatRoomId = ids.join("_");
        } else {
          return "Thiếu thông tin người nhận hoặc nhóm";
        }

        String messageId = const Uuid().v1();
        DateTime now = DateTime.now();

        Message message = Message(
          senderId: senderId,
          receiverId: groupId != null
              ? ''
              : receiverId!, // If it's a group, the receiver is groupId
          senderDisplayName: senderDisplayName,
          senderPhotoUrl: senderPhotoUrl,
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

        // update chat room info
        Map<String, dynamic> chatRoomData = {
          'lastMessage': text,
          'lastMessageSenderId': senderId,
          'lastMessageTime': Timestamp.fromDate(now),
        };

        // if it's a 1-1 chat, ensure both users are in 'users' array
        if (receiverId != null) {
          List<String> ids = [senderId, receiverId];
          ids.sort();
          chatRoomData['users'] = ids;
          // Mark as non-group chat
          chatRoomData['isGroup'] = false;
        }

        // Update last message info in chat room document
        await _firestore
            .collection('chats')
            .doc(chatRoomId)
            .set(chatRoomData, SetOptions(merge: true));

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
  Stream<QuerySnapshot> getMessages(String chatRoomId) {
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

  // Create a new group chat
  Future<String> createGroup({
    required String groupName,
    required String creatorId,
    required List<String> memberIds,
    Uint8List? groupIcon,
  }) async {
    // final FirebaseFirestore firestore = FirebaseFirestore.instance;
    String res = "Some error occurred";
    try {
      String groupId = const Uuid().v1();

      // Always add the creator to the member list.
      List<String> allMembers = [...memberIds, creatorId];
      // Delete duplicates
      allMembers = allMembers.toSet().toList();

      String groupIconUrl = '';
      if (groupIcon != null) {
        groupIconUrl = await StorageMethod().uploadImageToStorage(
          'groupIcons',
          groupIcon,
          true, // Use true to generate a unique ID for the image file
        );
      }

      Map<String, dynamic> groupData = {
        'chatRoomId': groupId,
        'groupName': groupName,
        'groupIconUrl': groupIconUrl, // Upload image URL
        'adminId': creatorId,
        'users': allMembers, // This array is used to query getUserChatRooms
        'isGroup': true, // Flag to mark as group chat
        'lastMessage': 'Nhóm đã được tạo',
        'lastMessageSenderId': creatorId,
        'lastMessageTime': Timestamp.now(),
      };

      await _firestore.collection('chats').doc(groupId).set(groupData);
      res = "success";
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  // Update group icon
  Future<String> updateGroupIcon(
    String groupId,
    Uint8List file,
    String? oldIconUrl,
  ) async {
    String res = "Some error occurred";
    try {
      // Delete the old image if it exists
      if (oldIconUrl != null && oldIconUrl.isNotEmpty) {
        try {
          await StorageMethod().deleteImageFromStorage(oldIconUrl);
        } catch (e) {
          avoidPrint("Warning: Could not delete old group icon: $e");
        }
      }

      // Upload the new image
      String newIconUrl = await StorageMethod().uploadImageToStorage(
        'groupIcons',
        file,
        true,
      );

      // Update the chat document
      await _firestore.collection('chats').doc(groupId).update({
        'groupIconUrl': newIconUrl,
      });

      res = "success";
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  // Leave a group chat
  Future<String> leaveGroup(String groupId, String userId) async {
    String res = "Some error occurred";
    try {
      DocumentReference chatDocRef = _firestore
          .collection('chats')
          .doc(groupId);

      // Atomically remove the user from the 'users' array
      await chatDocRef.update({
        'users': FieldValue.arrayRemove([userId]),
      });

      // Optional: Post a message that the user has left
      String messageId = const Uuid().v1();
      await chatDocRef.collection('messages').doc(messageId).set({
        'messageId': messageId,
        'senderId': '', // System message
        'senderDisplayName': 'Hệ thống',
        'senderPhotoUrl': 'assets/images/trevie.svg',
        'text': 'Một thành viên đã rời khỏi nhóm.',
        'type': 'text',
        'datePublished': Timestamp.now(),
      });

      res = "success";
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  // Remove a user from a group (Admin only)
  Future<String> removeUserFromGroup(
      String groupId, String userIdToRemove, String adminId) async {
    String res = "Some error occurred";
    try {
      DocumentReference chatDocRef =
          _firestore.collection('chats').doc(groupId);

      // First, verify that the person performing the action is the admin
      DocumentSnapshot chatDoc = await chatDocRef.get();
      if (!chatDoc.exists) {
        return "Không tìm thấy nhóm.";
      }
      Map<String, dynamic> groupData = chatDoc.data() as Map<String, dynamic>;
      if (groupData['adminId'] != adminId) {
        return "Bạn không có quyền thực hiện hành động này.";
      }

      // Prevent admin from removing themselves with this method
      if (userIdToRemove == adminId) {
        return "Quản trị viên không thể tự xóa chính mình.";
      }

      // Atomically remove the user from the 'users' array
      await chatDocRef.update({
        'users': FieldValue.arrayRemove([userIdToRemove])
      });

      // Optional: Post a system message that the user has been removed
      String messageId = const Uuid().v1();
      await chatDocRef.collection('messages').doc(messageId).set({
        'messageId': messageId,
        'senderId': '', // System message
        'senderDisplayName': 'Hệ thống',
        'senderPhotoUrl': 'assets/images/trevie.svg',
        'text': 'Một thành viên đã bị xóa khỏi nhóm.',
        'type': 'text',
        'datePublished': Timestamp.now(),
      });

      res = "success";
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  // Add a user to a group (All members can add a new user)
  Future<String> addUserToGroup(
      String groupId, List<String> userIdsToAdd) async {
    String res = "Some error occurred";
    try {
      DocumentReference chatDocRef =
          _firestore.collection('chats').doc(groupId);

      DocumentSnapshot chatDoc = await chatDocRef.get();
      if (!chatDoc.exists) {
        return "Không tìm thấy nhóm.";
      }

      // Atomically add the user to the 'users' array
      await chatDocRef.update({
        'users': FieldValue.arrayUnion(userIdsToAdd)
      });

      // Optional: Post a system message that the user has been added
      String messageId = const Uuid().v1();
      await chatDocRef.collection('messages').doc(messageId).set({
        'messageId': messageId,
        'senderId': '', // System message
        'senderDisplayName': 'Hệ thống',
        'senderPhotoUrl': 'assets/images/trevie.svg',
        'text': '${userIdsToAdd.length} thành viên đã được thêm vào nhóm.',
        'type': 'text',
        'datePublished': Timestamp.now(),
      });

      res = "success";
    } catch (e) {
      res = e.toString();
    }
    return res;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String receiverId;
  final String text;
  final String type; // 'text', 'image'
  final DateTime datePublished;
  final String messageId;

  Message({
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.type,
    required this.datePublished,
    required this.messageId,
  });

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'type': type,
      'datePublished': Timestamp.fromDate(datePublished),
      'messageId': messageId,
    };
  }

  static Message fromSnap(DocumentSnapshot snapshot) {
    var snapshotData = snapshot.data() as Map<String, dynamic>;

    // Helper funtion to safely parse DateTime
    DateTime? parseDateField(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        return DateTime.tryParse(value);
      } else if (value is Timestamp) {
        return value.toDate();
      }

      return null;
    }

    return Message(
      senderId: snapshotData['senderId'] ?? '',
      receiverId: snapshotData['receiverId'] ?? '',
      text: snapshotData['text'] ?? '',
      type: snapshotData['type'] ?? 'text',
      datePublished:
          parseDateField(snapshotData['datePublished']) ?? DateTime.now(),
      messageId: snapshotData['messageId'] ?? '',
    );
  }
}

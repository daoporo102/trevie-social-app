import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String postId;
  final String uid;
  final String postText;
  final String displayName;
  final String postUrl;
  final String profImage;
  final DateTime datePublished;
  final List<String> likes;
  final DateTime? dateUpdated;
  final DateTime lastDateModified;

  const Post({
    required this.postId,
    required this.uid,
    required this.postText,
    required this.postUrl,
    required this.profImage,
    required this.datePublished,
    required this.likes,
    required this.displayName,
    this.dateUpdated,
    required this.lastDateModified,
  });

  Map<String, dynamic> toJson() => {
    "postId": postId,
    "uid": uid,
    "postText": postText,
    "postUrl": postUrl,
    "profImage": profImage,
    "datePublished": Timestamp.fromDate(datePublished),
    "likes": likes,
    "displayName": displayName,
    "dateUpdated": Timestamp.fromDate(dateUpdated!),
    "lastDateModified": Timestamp.fromDate(lastDateModified),
  };

  static Post fromSnap(DocumentSnapshot snapshot) {
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

    return Post(
      postId: snapshotData['postId'] ?? '',
      uid: snapshotData['uid'] ?? '',
      postText: snapshotData['postText'] ?? '',
      postUrl: snapshotData['postUrl'] ?? '',
      profImage: snapshotData['profImage'] ?? '',
      datePublished:
          parseDateField(snapshotData['datePublished']) ?? DateTime.now(),
      likes: snapshotData['likes'] ?? [],
      displayName: snapshotData['displayName'] ?? '',
      dateUpdated: parseDateField(snapshotData['dateUpdated']),
      lastDateModified:
          parseDateField(snapshotData['lastDateModified']) ?? DateTime.now(),
    );
  }
}

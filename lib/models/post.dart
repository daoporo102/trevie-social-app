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
  });

  Map<String, dynamic> toJson() => {
    "postId": postId,
    "uid": uid,
    "postText": postText,
    "postUrl": postUrl,
    "profImage": profImage,
    "datePublished": datePublished.toIso8601String(),
    "likes": likes,
    "displayName": displayName,
    "dateUpdated": dateUpdated?.toIso8601String(),
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
      postId: snapshotData.containsKey("postId") ? snapshotData['postId'] : '',
      uid: snapshotData.containsKey("uid") ? snapshotData['uid'] : '',
      postText: snapshotData.containsKey("postText")
          ? snapshotData['postText']
          : '',
      postUrl: snapshotData.containsKey("postUrl")
          ? snapshotData['postUrl']
          : '',
      profImage: snapshotData.containsKey("profImage")
          ? snapshotData['profImage']
          : '',
      datePublished: snapshotData.containsKey("datePublished")
          ? parseDateField(snapshotData['datePublished']) ?? DateTime.now()
          : DateTime.now(),
      likes: snapshotData.containsKey("likes") ? snapshotData['likes'] : 0,
      displayName: snapshotData.containsKey("displayName")
          ? snapshotData['displayName']
          : '',
      dateUpdated: snapshotData.containsKey("dateUpdated")
          ? parseDateField(snapshotData['dateUpdated'])
          : null,
    );
  }
}

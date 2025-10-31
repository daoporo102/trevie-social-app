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
  
  const Post({
    required this.postId,
    required this.uid,
    required this.postText,
    required this.postUrl,
    required this.profImage,
    required this.datePublished,
    required this.likes,
    required this.displayName,
  });

  Map<String, dynamic> toJson() => {
    "postId": postId,
    "uid": uid,
    "postText": postText,
    "postUrl": postUrl,
    "profImage": profImage,
    "datePublished": datePublished,
    "likes": likes,
    "displayName": displayName,
  };

  static Post fromSnap(DocumentSnapshot snapshot) {
    var snapshotData = snapshot.data() as Map<String, dynamic>;
    return Post(
      postId: snapshotData.containsKey("postId")
          ? snapshotData['postId']
          : '',
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
          ? DateTime.parse(snapshotData['datePublished'])
          : DateTime.now(),
      likes: snapshotData.containsKey("likes") ? snapshotData['likes'] : 0,
      displayName: snapshotData.containsKey("displayName")
          ? snapshotData['displayName']
          : '',
    );
  }
}

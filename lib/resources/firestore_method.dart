import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:social_media_app/models/post.dart';
import 'package:social_media_app/resources/storage_method.dart';
import 'package:uuid/uuid.dart';

class FirestoreMethod {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //upload post
  Future<String> uploadPost(
    String postText,
    Uint8List file,
    String uid,
    String displayName,
    String profImage,
  ) async {
    // asking uid here because we dont want to make extra calls to firebase auth when we can just get from our state management
    String res = "Some error occurred";
    try {
      String photoUrl = await StorageMethod().uploadImageToStorage(
        'posts',
        file,
        true,
      );
      // creates unique id based on time
      String postId = const Uuid().v1();

      Post post = Post(
        postId: postId,
        uid: uid,
        postText: postText,
        postUrl: photoUrl,
        datePublished: DateTime.now(),
        likes: [],
        displayName: displayName,
        profImage: profImage,
      );

      _firestore.collection('posts').doc(postId).set(post.toJson());

      res = "success";
    } catch (e) {
      res = e.toString();
    }
    return res;
  }
}

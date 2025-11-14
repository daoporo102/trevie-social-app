import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:social_media_app/models/post.dart';
import 'package:social_media_app/resources/storage_method.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:uuid/uuid.dart';

class FirestoreMethod {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

<<<<<<< Updated upstream
      _firestore.collection('posts').doc(postId).set(post.toJson());
=======
      await _firestore.collection('posts').doc(postId).set({
        ...post.toJson(),
        'datePublished':
            FieldValue.serverTimestamp(), // consistent across clients
      });
>>>>>>> Stashed changes

      res = "success";
    } catch (e) {
      res = e.toString();
<<<<<<< Updated upstream
=======
      avoidPrint(res);
      res = "Đã có lỗi xảy ra, vui lòng thử lại";
>>>>>>> Stashed changes
    }
    return res;
  }

  //like post
  Future<void> likePost(String postId, String uid, List likes) async {
    try {
      if (likes.contains(uid)) {
        //unlike the post
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        //like the post
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([uid]),
        });
      }
    } catch (e) {
      avoidPrint(e.toString());
    }
  }

  Future<String> postComment(
    String postId,
    String text,
    String uid,
    String name,
    String profilePic,
  ) async {
    String res = "Some error occurred";
    try {
      if (text.isNotEmpty) {
        String commentId = const Uuid().v1();
        await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .set({
              'profilePic': profilePic,
              'name': name,
              'uid': uid,
              'text': text,
              'commentId': commentId,
              'datePublished': DateTime.now(),
            });
        res = 'success';
      } else {
        res="Please enter text";
      }
    } catch (e) {
      avoidPrint(e.toString());
    }
    return res;
  }

  //Deleting post
  Future<void> deletePost(String postId) async {
    final uid = _auth.currentUser!.uid;
    try {
      // Get the post document to retrieve the postUrl
      DocumentSnapshot postDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .get();

      if (postDoc.exists) {
        String postUrl = (postDoc.data() as Map<String, dynamic>)['postUrl'];

        // Delete post collection in Firestore database
        await _firestore.collection('posts').doc(postId).delete();

        // Delete post's image in storage if it exists
        if (postUrl != null && postUrl.isNotEmpty) {
          await StorageMethod().deleteImageFromStorage(postUrl);
        }
      }
    } catch (e) {
      avoidPrint(e.toString());
      rethrow;
    }
  }
}

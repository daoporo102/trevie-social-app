import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:social_media_app/models/post.dart';
import 'package:social_media_app/resources/storage_method.dart';
import 'package:social_media_app/utils/utils.dart';
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
    String res = "Một lỗi đã xảy ra";
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
    } on FirebaseException catch (e) {
      avoidPrint("Firebase error in likePost: ${e.code} - ${e.message}");
      throw 'Đã có lỗi xảy ra, vui lòng thử lại sau: ${e.message ?? e.code}';
    } catch (e) {
      avoidPrint("Unknown error in likePost: $e");
      throw 'Đã có lỗi xảy ra, vui lòng thử lại sau';
    }
  }

  Future<String> postComment(
    String postId,
    String text,
    String uid,
    String name,
    String profilePic,
  ) async {
    String res = "Một lỗi đã xảy ra";
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
        res = "Vui lòng nhập bình luận";
      }
    } catch (e) {
      avoidPrint(e.toString());
      res = "Đã xảy ra lỗi, vui lòng thử lại sau";
    }
    return res;
  }

  //Deleting post
  Future<void> deletePost(String postId) async {
    try {
      // Get the post document to retrieve the postUrl
      DocumentSnapshot postDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .get();

      // Check if the document exists
      if (postDoc.exists) {
        String postUrl = (postDoc.data() as Map<String, dynamic>)['postUrl'];

        // Delete post collection in Firestore database
        await _firestore.collection('posts').doc(postId).delete();

        // Delete post's image in storage if it exists
        if (postUrl.isNotEmpty) {
          await StorageMethod().deleteImageFromStorage(postUrl);
        }
      }
    } catch (e) {
      avoidPrint(e.toString());
      rethrow;
    }
  }

  Future<void> followUser(String uid, String followId) async {
    try {
      //fetching all user data
      DocumentSnapshot snap = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      //getting following list
      List following = (snap.data()! as dynamic)['following'];

      //if already following then unfollow
      if (following.contains(followId)) {
        //remove follower
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayRemove([uid]),
        });
        //remove following
        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayRemove([followId]),
        });
      } else {
        //add follower
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayUnion([uid]),
        });
        //add following
        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayUnion([followId]),
        });
      }
    } catch (e) {
      avoidPrint(e.toString());
    }
  }

  //update post
  Future<String> updatePost(
    String postId,
    String postText,
    Uint8List? file,
    String? existingImageUrl,
  ) async {
    String res = "Một lỗi đã xảy ra";
    try {
      if (file != null) {
        // Delete the old image from storage if it exists
        if (existingImageUrl != null && existingImageUrl.isNotEmpty) {
          await StorageMethod().deleteImageFromStorage(existingImageUrl);
        }

        // Upload the new image to storage
        String newPhotoUrl = await StorageMethod().uploadImageToStorage(
          'posts',
          file,
          true,
        );

        // Update the post document with the new image URL and text
        await _firestore.collection('posts').doc(postId).update({
          'postUrl': newPhotoUrl,
          'postText': postText,
        });
      } else {
        // If no new file is provided, just update the text
        await _firestore.collection('posts').doc(postId).update({
          'postText': postText,
        });
      }
      res = 'success';
    } catch (e) {
      avoidPrint(e.toString());
    }
    return res;
  }
}

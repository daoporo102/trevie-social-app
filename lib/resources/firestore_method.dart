import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:social_media_app/models/comment.dart';
import 'package:social_media_app/models/post.dart';
import 'package:social_media_app/resources/storage_method.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:uuid/uuid.dart';

class FirestoreMethod {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final userUid = FirebaseAuth.instance.currentUser?.uid;

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
      // Validate proImage before proceeding
      if (profImage.isEmpty) {
        return "Ảnh đại diện không hợp lệ";
      }

      String photoUrl = await StorageMethod().uploadImageToStorage(
        'posts',
        file,
        true,
      );

      // Check if upload succeeded
      if (photoUrl.isEmpty) {
        return "Lỗi tải ảnh lên, vui lòng thử lại";
      }
      // creates unique id based on time
      String postId = const Uuid().v1();
      // get current time
      final now = DateTime.now();

      Post post = Post(
        postId: postId,
        uid: uid,
        postText: postText,
        displayName: displayName,
        postUrl: photoUrl,
        profImage: profImage,
        datePublished: now,
        likes: [],
        dateUpdated: null,
        lastDateModified: now,
        reshareCount: 0,
        originalPostId: null,
        originalUid: null,
        originalPostText: null,
        originalDisplayName: null,
        originalProfImage: null,
      );

      _firestore.collection('posts').doc(postId).set(post.toJson());

      res = "success";
    } catch (e) {
      avoidPrint("Error in uploadPost: ${e.toString()}");
      res = "Đã xảy ra lỗi, vui lòng thử lại sau";
    }
    return res;
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
      final now = DateTime.now();
      Map<String, dynamic> updateData = {
        'postText': postText,
        'dateUpdated': Timestamp.fromDate(now),
        'lastDateModified': Timestamp.fromDate(now),
      };
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

        // Add the new photo Url to updateData
        updateData['postUrl'] = newPhotoUrl;

        // Update the post document with the new image URL, text and date
        await _firestore.collection('posts').doc(postId).update(updateData);

        res = 'success';
      } else {
        // If no new file is provided, just update the text
        await _firestore.collection('posts').doc(postId).update(updateData);
      }
      res = 'success';
    } catch (e) {
      avoidPrint(e.toString());
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
    // get current time
    final now = DateTime.now();
    try {
      if (text.isNotEmpty) {
        String commentId = const Uuid().v1();

        // Create Comment object
        Comment comment = Comment(
          uid: uid,
          commentId: commentId,
          name: name,
          commentText: text,
          profilePic: profilePic,
          datePublished: now,
          dateUpdated: null,
          lastDateModified: now,
        );

        // Add comment to Firestore database
        await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .set(comment.toJson());

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

  // Deleting comment
  Future<String> deleteComment(String postId, String commentId) async {
    String res = "Một lỗi đã xảy ra";
    try {
      // Get the comment document
      DocumentSnapshot commentDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .get();

      if (userUid == commentDoc['uid']) {
        // Check if the document exists
        if (commentDoc.exists && commentDoc.data() != null) {
          // Delete comment from Firestore database
          await _firestore
              .collection('posts')
              .doc(postId)
              .collection('comments')
              .doc(commentId)
              .delete();

          res = 'success';
          return res;
        } else {
          res = 'Bình luận không tồn tại!';
          avoidPrint(res);
          return res;
        }
      } else {
        res = 'Bạn không có quyền xoá bình luận này!';
        avoidPrint(res);
        return res;
      }
    } catch (e) {
      avoidPrint("Error in deleteComment: ${e.toString()}");
      res = 'Đã xảy ra lỗi khi xoá bình luận';
    }
    return res;
  }

  //Deleting post
  Future<String> deletePost(String postId) async {
    String res = "Một lỗi đã xảy ra";
    try {
      // Get the post document to retrieve the postUrl
      DocumentSnapshot postDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .get();

      if (postDoc.data() == null || !postDoc.exists) {
        res = 'Bài viết không tồn tại hoặc đã bị xoá!';
        avoidPrint(res);
        return res;
      }

      final postData = postDoc.data() as Map<String, dynamic>;

      // Check ownership
      if (userUid != postDoc['uid']) {
        res = 'Bạn không có quyền xoá bài viết này!';
        avoidPrint(res);
        return res;
      }

      String postUrl = postData['postUrl'];

      // Check if this is a reshared post
      bool isReshare = postData['originalPostId'] != null;

      // Delete post collection in Firestore database
      await _firestore.collection('posts').doc(postId).delete();

      // Only delete image if it's not a reshared post (reshares reuse the original image)
      if (!isReshare && postUrl.isNotEmpty) {
        try {
          await StorageMethod().deleteImageFromStorage(postUrl);
        } catch (storageError) {
          avoidPrint(
            "Storage deletion warning (post already deleted): $storageError",
          );
        }
      }

      // If this is a post is a reshared post
      if (isReshare && postData['originalPostId'] != null) {
        String originalPostId = postData['originalPostId'];
        // Decrement reshareCount on the original post
        try {
          await _firestore.collection('posts').doc(originalPostId).update({
            'reshareCount': FieldValue.increment(-1),
          });
        } catch (e) {
          avoidPrint(
            "Could not decrement reshareCount (original post may be deleted): $e",
          );
        }
      }

      res = 'success';
    } catch (e) {
      res = "Có lỗi xảy ra, vui lòng thử lại sau";
      avoidPrint("Error in deletePost: ${e.toString()}");
      rethrow;
    }
    return res;
  }

  // Delete comment
  Future<String> updateComment(
    String postId,
    String commentId,
    String commentText,
  ) async {
    String res = "Một lỗi đã xảy ra";
    try {
      final now = DateTime.now();
      Map<String, dynamic> updateData = {
        'commentText': commentText,
        'dateUpdated': Timestamp.fromDate(now),
        'lastDateModified': Timestamp.fromDate(now),
      };

      if (commentText.isNotEmpty) {
        // Update the comment document with the new text and date
        await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .update(updateData);
      } else {
        res = "Vui lòng nhập bình luận";
        return res;
      }
      res = 'success';
    } catch (e) {
      avoidPrint(e.toString());
    }
    return res;
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

  // Reshare post
  Future<String> resharePost(
    String postText,
    Post originalPost,
    String uid,
    String displayName,
    String profImage,
  ) async {
    String res = "Một lỗi đã xảy ra";
    try {
      // creates unique id based on time
      String postId = const Uuid().v1();
      // get current time
      final now = DateTime.now();

      // Create the new post data
      Post newPost = Post(
        postId: postId,
        uid: uid,
        postText: postText,
        displayName: displayName,
        postUrl: originalPost.postUrl,
        profImage: profImage,
        datePublished: now,
        likes: [],
        dateUpdated: null,
        lastDateModified: now,
        reshareCount: 0,
        originalPostId: originalPost.postId,
        originalUid: originalPost.uid,
        originalPostText: originalPost.postText,
        originalDisplayName: originalPost.displayName,
        originalProfImage: originalPost.profImage,
      );

      // Reference to the original post
      DocumentReference originalPostRef = _firestore
          .collection('posts')
          .doc(originalPost.postId);

      // Original post exists, proceed with resharing
      if (await originalPostRef.snapshots().isEmpty) {
        avoidPrint('Original post does not exist.');
        res = 'Bài viết gốc không tồn tại hoặc đã bị xoá!';
        return res;
      }

      // Add the new post to Firestore
      await _firestore.collection('posts').doc(postId).set(newPost.toJson());

      // Increment reshareCount on the original post
      await _firestore.collection('posts').doc(originalPost.postId).update({
        'reshareCount': FieldValue.increment(1),
      });

      res = 'success';
    } catch (e) {
      avoidPrint("Error in resharePost: ${e.toString()}");
      res = "Đã xảy ra lỗi, vui lòng thử lại sau";
    }
    return res;
  }
}

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:social_media_app/models/user.dart' as model;
import 'package:social_media_app/resources/storage_method.dart';
import 'package:social_media_app/utils/utils.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a static flag that can be accessed before UserProvider
  static bool _isCheckingLogin = false;
  static bool get isCheckingLogin => _isCheckingLogin;

  Future<model.User> getUserDetails() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return model.User(
        uid: '',
        displayName: '',
        email: '',
        photoUrl: '',
        followers: [],
        following: [],
        bio: '',
        dateOfBirth: null,
        createdAt: DateTime.now(),
        isSuspended: false,
        suspendedAt: null,
        isDeleted: false,
      );
    }

    final DocumentSnapshot snap = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!snap.exists) {
      return model.User(
        displayName: currentUser.displayName ?? '',
        uid: currentUser.uid,
        email: currentUser.email ?? '',
        photoUrl: currentUser.photoURL ?? '',
        followers: [],
        following: [],
        bio: '',
        dateOfBirth: null,
        createdAt: DateTime.now(),
        isSuspended: false,
        suspendedAt: null,
        isDeleted: false,
      );
    }

    final userData = snap.data() as Map<String, dynamic>;

    // Check if suspended or deleted
    if (userData['isSuspended'] == true || userData['isDeleted'] == true) {
      // Only sign out if NOT in login check mode
      if (!_isCheckingLogin) {
        await signOut();
      }
      throw Exception('Account is suspended or deleted');
    }

    return model.User.fromSnap(snap);
  }

  //sign up user
  Future<String> signUpUser({
    required String displayName,
    required String email,
    required String password,
    required Uint8List file,
  }) async {
    String res = "Một lỗi đã xảy ra";
    try {
      if (email.isNotEmpty && password.isNotEmpty && displayName.isNotEmpty) {
        //register user in auth with email and password
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        //debugging print statement to verify user creation
        avoidPrint("Firebase Auth User UID: ${cred.user!.uid}");

        final photoUrl = await StorageMethod().uploadImageToStorage(
          'profilePics',
          file,
          false,
        );

        //add user to database
        final user = model.User(
          displayName: displayName,
          uid: cred.user!.uid,
          email: email,
          photoUrl: photoUrl,
          followers: [],
          following: [],
          bio: '',
          dateOfBirth: DateTime.now(),
          createdAt: DateTime.now(),
          isSuspended: false,
          suspendedAt: null,
          isDeleted: false,
          role: 'user',
        );

        //adding user in our database
        await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .set(user.toJson());

        res = "success";
      } else {
        res = "Vui lòng điền tất cả các thông tin";
      }
    } on FirebaseAuthException catch (err) {
      if (err.code == 'email-already-in-use') {
        res = "Email đã được sử dụng";
      } else if (err.code == 'invalid-email') {
        res = "Địa chỉ email không hợp lệ";
      } else if (err.code == 'weak-password') {
        res = "Mật khẩu phải có ít nhất 6 ký tự";
      } else if (err.code == 'network-request-failed') {
        res = "Lỗi mạng, vui lòng thử lại sau";
      } else {
        res = err.toString();
        avoidPrint(res);
        res = "Đã xảy ra lỗi, vui lòng thử lại sau";
      }
    }
    return res;
  }

  //login user
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Một lỗi đã xảy ra";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        // Set flag BEFORE signIn
        _isCheckingLogin = true;
        avoidPrint("Set _isCheckingLogin = true");

        //login user in auth with email and password
        UserCredential cred = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Check if user is suspended or deleted
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .get();

        if (!userDoc.exists) {
          await _auth.signOut();
          _isCheckingLogin = false;
          return "Tài khoản không tồn tại";
        }

        final userData = userDoc.data() as Map<String, dynamic>;

        // Check if account is deleted
        if (userData['isDeleted'] == true) {
          final deletedAt = userData['deletedAt'] as Timestamp?;
          final deletionDate = deletedAt?.toDate();
          final deletionReason = userData['deletionReason'] as String?;

          // Don't reset flag yet - let UI handle navigation first
          avoidPrint("Account deleted, flag still true");
          avoidPrint("Deletion reason: $deletionReason");

          // Reset flag AFTER determining deletion (UI will handle navigation)
          _isCheckingLogin = false;
          avoidPrint("Set _isCheckingLogin = false (deleted - UI will handle)");

          // Return special code with timestamp and reason
          return "DELETED:${deletionDate?.millisecondsSinceEpoch ?? 0}:${deletionReason ?? ''}";
        }

        // Check if account is suspended
        if (userData['isSuspended'] == true) {
          final suspendedAt = userData['suspendedAt'] as Timestamp?;
          final suspensionDate = suspendedAt?.toDate();

          // Don't reset flag yet - let UI handle navigation first
          avoidPrint("Account suspended, flag still true");

          // Reset flag AFTER determining suspension (UI will handle navigation)
          // But keep user signed in for AccountBlockedScreen to display
          _isCheckingLogin = false;
          avoidPrint(
            "Set _isCheckingLogin = false (suspended - UI will handle)",
          );

          // Return special code
          return "SUSPENDED:${suspensionDate?.millisecondsSinceEpoch ?? 0}";
        }

        //Reset flag for successful login
        _isCheckingLogin = false;
        avoidPrint("Set _isCheckingLogin = false (success)");

        res = "success";
      } else {
        res = "Vui lòng điền tất cả các thông tin";
      }
    } on FirebaseAuthException catch (err) {
      // Reset flag on error
      _isCheckingLogin = false;

      if (err.code == 'user-not-found') {
        res = "Không tìm thấy người dùng với email này";
      } else if (err.code == 'invalid-email') {
        res = "Địa chỉ email không hợp lệ";
      } else if (err.code == 'wrong-password') {
        res = "Mật khẩu không đúng";
      } else if (err.code == 'network-request-failed') {
        res = "Lỗi mạng, vui lòng thử lại sau";
      } else if (err.code == 'too-many-requests') {
        res = "Quá nhiều lần đăng nhập. Vui lòng thử lại sau.";
      } else if (err.code == 'invalid-credential') {
        res = "Email hoặc mật khẩu không hợp lệ.";
      } else {
        res = err.toString();
        avoidPrint(res);
        res = "Đã xảy ra lỗi, vui lòng thử lại sau";
      }
    }
    return res;
  }

  //sign out method
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      avoidPrint("Successfully signed out from Firebase Auth");
    } catch (e) {
      avoidPrint("Error signing out: $e");
      rethrow;
    }
  }

  // Fixed update user profile method
  Future<String> updateUserProfile(
    String uid,
    String displayName,
    Uint8List? file,
    String? existingImageUrl,
    String? bio,
    DateTime? dateOfBirth,
  ) async {
    String res = "Một lỗi đã xảy ra";

    try {
      String? newPhotoUrl;
      Map<String, dynamic> updateData = {'displayName': displayName};

      // Add bio if provided
      if (bio != null && bio.isNotEmpty) {
        updateData['bio'] = bio;
      }

      // Add dateOfBirth if provided
      if (dateOfBirth != null) {
        updateData['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
      }

      // Handle profile picture update
      if (file != null) {
        // Delete the old profile picture if it exists
        if (existingImageUrl != null && existingImageUrl.isNotEmpty) {
          try {
            await StorageMethod().deleteImageFromStorage(existingImageUrl);
          } catch (e) {
            avoidPrint("Warning: Could not delete old profile picture: $e");
            // Continue anyway
          }
        }

        // Upload the new profile picture
        newPhotoUrl = await StorageMethod().uploadImageToStorage(
          'profilePics',
          file,
          false,
        );

        if (newPhotoUrl.isEmpty) {
          return "Lỗi tải ảnh lên, vui lòng thử lại";
        }

        updateData['photoUrl'] = newPhotoUrl;
      }

      // Update user document
      await _firestore.collection('users').doc(uid).update(updateData);

      // Update all posts and comments with new data
      await _updateUserPosts(uid, displayName, newPhotoUrl);
      await _updateUserComments(uid, displayName, newPhotoUrl);

      res = "success";
    } catch (e) {
      avoidPrint("Error updating user profile: ${e.toString()}");
      res = "Đã xảy ra lỗi, vui lòng thử lại sau";
    }

    return res;
  }

  /// Check if current user's account is suspended or deleted
  Future<Map<String, dynamic>> checkUserAccountStatus() async {
    try {
      final currentUser = _auth.currentUser;

      avoidPrint("=== Checking Account Status ===");
      avoidPrint("Current User UID: ${currentUser?.uid}");

      if (currentUser == null) {
        avoidPrint("ERROR: No current user found");
        return {'isValid': false, 'reason': 'Không tìm thấy người dùng'};
      }

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      avoidPrint("User document exists: ${userDoc.exists}");

      if (!userDoc.exists) {
        avoidPrint("ERROR: User document doesn't exist");
        return {'isValid': false, 'reason': 'Tài khoản không tồn tại'};
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Debug: Print actual values
      avoidPrint("isDeleted: ${userData['isDeleted']}");
      avoidPrint("isSuspended: ${userData['isSuspended']}");
      avoidPrint("suspendedAt: ${userData['suspendedAt']}");

      // Check if deleted
      if (userData['isDeleted'] == true) {
        // await signOut();
        avoidPrint("Account is deleted!");
        final deletionReason = userData['deletionReason'] as String?;
        return {
          'isValid': false,
          'reason': 'Tài khoản đã bị xóa',
          'deletionReason': deletionReason,
        };
      }

      // Check if suspended
      if (userData['isSuspended'] == true) {
        avoidPrint("Account is suspended!");

        final suspensionReason = userData['suspensionReason'] as String?;
        return {
          'isValid': false,
          'reason': 'Tài khoản đã bị đình chỉ hoạt động',
          'suspensionReason': suspensionReason,
        };
      }

      // Account is valid (not deleted, not suspended)
      avoidPrint("Account is VALID - allowing login");

      return {'isValid': true, 'reason': 'success'};
    } catch (e) {
      avoidPrint("Error checking account status: $e");
      return {'isValid': false, 'reason': 'Lỗi kiểm tra trạng thái tài khoản'};
    }
  }

  Future<void> _updateUserPosts(
    String uid,
    String displayName,
    String? newPhotoUrl,
  ) async {
    try {
      // Fetch all posts made by the user
      QuerySnapshot userPostsSnapshot = await _firestore
          .collection('posts')
          .where('uid', isEqualTo: uid)
          .get();

      if (userPostsSnapshot.docs.isEmpty) {
        avoidPrint("No posts found for user $uid");
        return;
      }

      // Update each post
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      for (var doc in userPostsSnapshot.docs) {
        Map<String, dynamic> updateData = {'displayName': displayName};

        // Only update profImage if a new photo was uploaded
        if (newPhotoUrl != null) {
          updateData['profImage'] = newPhotoUrl;
        }

        batch.update(doc.reference, updateData);
        batchCount++;

        // Commit every 500 operations (Firestore limit)
        if (batchCount >= 500) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      // Commit remaining operations
      if (batchCount > 0) {
        await batch.commit();
      }

      avoidPrint(
        "Updated ${userPostsSnapshot.docs.length} posts for user $uid",
      );
    } catch (e) {
      avoidPrint("Error updating user posts: $e");
      // Don't rethrow - we still want profile update to succeed
    }
  }

  Future<void> _updateUserComments(
    String uid,
    String displayName,
    String? newPhotoUrl,
  ) async {
    try {
      // Fetch all posts to find comments made by the user
      QuerySnapshot allPostsSnapshot = await _firestore
          .collection('posts')
          .get();

      WriteBatch batch = _firestore.batch();
      int operationCount = 0;
      int totalUpdated = 0;

      for (var postDoc in allPostsSnapshot.docs) {
        // Get comments subcollection for each post
        QuerySnapshot commentsSnapshot = await postDoc.reference
            .collection('comments')
            .where('uid', isEqualTo: uid)
            .get();

        for (var commentDoc in commentsSnapshot.docs) {
          Map<String, dynamic> updateData = {'name': displayName};

          // Only update profImage if a new photo was uploaded
          if (newPhotoUrl != null) {
            updateData['profImage'] = newPhotoUrl;
          }

          batch.update(commentDoc.reference, updateData);
          operationCount++;
          totalUpdated++;

          // Commit batch if operation count reaches 500
          if (operationCount >= 500) {
            await batch.commit();
            batch = _firestore.batch();
            operationCount = 0;
          }
        }
      }

      // Commit remaining operations
      if (operationCount > 0) {
        await batch.commit();
      }

      avoidPrint("Updated $totalUpdated comments for user $uid");
    } catch (e) {
      avoidPrint("Error updating user comments: $e");
      // Don't rethrow - we still want profile update to succeed
    }
  }
}

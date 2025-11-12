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
      );
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
        //login user in auth with email and password
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        res = "success";
      } else {
        res = "Vui lòng điền tất cả các thông tin";
      }
    } on FirebaseAuthException catch (err) {
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
    await _auth.signOut();
  }
}

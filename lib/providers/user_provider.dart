import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:social_media_app/models/user.dart' as model;
import 'package:social_media_app/resources/auth_methods.dart';
import 'package:social_media_app/utils/utils.dart';

class UserProvider with ChangeNotifier {
  model.User? _user;
  final AuthMethods _authMethod = AuthMethods();
  StreamSubscription<DocumentSnapshot>? _userStatusSubscription;

  UserProvider() {
    FirebaseAuth.instance.authStateChanges().listen((firebaseUser) {
      avoidPrint("Auth state changed: ${firebaseUser?.uid ?? 'null'}");
      avoidPrint(
        "AuthMethods.isCheckingLogin: ${AuthMethods.isCheckingLogin}",
      );

      if (firebaseUser == null) {
        // User signed out - clear everything
        avoidPrint("User signed out, clearing provider");
        _user = null;
        _userStatusSubscription?.cancel();
        _userStatusSubscription = null;
        notifyListeners();
      } else {
        // User signed in
        avoidPrint("User signed in: ${firebaseUser.uid}");
        refreshUser();

        // Check the static flag from AuthMethods
        if (!AuthMethods.isCheckingLogin) {
          avoidPrint("Starting listener (not in login check)");
          _listenToUserStatus(firebaseUser.uid);
        } else {
          avoidPrint("Skipping listener (in login check mode)");
          // Don't start listener - suspended user is viewing AccountBlockedScreen
        }
      }
    });
  }

  // Getter that can return null if user is not loaded
  model.User? get getUserrOrNull => _user;

  Future<void> refreshUser() async {
    try {
      avoidPrint("Refreshing user data...");
      model.User user = await _authMethod.getUserDetails();
      _user = user;
      avoidPrint("User data refreshed: ${user.displayName}");
      notifyListeners();
    } catch (e) {
      avoidPrint("Error refreshing user: $e");
      _user = null;
      notifyListeners();
    }
  }

  void _listenToUserStatus(String uid) {
    _userStatusSubscription?.cancel();

    avoidPrint("Starting real-time listener for: $uid");

    _userStatusSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (snapshot) {
            avoidPrint("User document updated");

            if (!snapshot.exists || snapshot.data() == null) {
              avoidPrint("User document deleted!");
              FirebaseAuth.instance.signOut();
              _user = null;
              notifyListeners();
              return;
            }

            final data = snapshot.data() as Map<String, dynamic>;
            final isSuspended = data['isSuspended'] == true;
            final isDeleted = data['isDeleted'] == true;

            avoidPrint(
              "Status - Suspended: $isSuspended, Deleted: $isDeleted",
            );

            if (isSuspended || isDeleted) {
              avoidPrint(
                "Account suspended/deleted while using app, signing out...",
              );
              FirebaseAuth.instance.signOut();
              _user = null;
              notifyListeners();
            } else {
              refreshUser();
            }
          },
          onError: (error) {
            avoidPrint("Error listening to user status: $error");
          },
        );
  }

  @override
  void dispose() {
    _userStatusSubscription?.cancel();
    super.dispose();
  }
}

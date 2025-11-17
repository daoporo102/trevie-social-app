import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;
  final String bio;
  // final DateTime dateOfBirth;
  final List followers;
  final List following;

  const User({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.bio,
    // required this.dateOfBirth,
    required this.followers,
    required this.following,
  });

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "displayName": displayName,
    "email": email,
    "photoUrl": photoUrl,
    "followers": followers,
    "following": following,
  };

  static User fromSnap(DocumentSnapshot spapshot) {
    var snapshotData = spapshot.data() as Map<String, dynamic>;

    return User(
      uid: snapshotData.containsKey("uid") ? snapshotData["uid"] : '',
      displayName: snapshotData.containsKey("displayName")
          ? snapshotData["displayName"]
          : '',
      email: snapshotData.containsKey("email") ? snapshotData["email"] : '',
      photoUrl: snapshotData.containsKey("photoUrl")
          ? snapshotData["photoUrl"]
          : '',
      followers: snapshotData.containsKey("followers")
          ? snapshotData["followers"]
          : [],
      following: snapshotData.containsKey("following")
          ? snapshotData["following"]
          : [],
      bio: snapshotData.containsKey("bio")
          ? snapshotData["bio"]
          : '',
    );
  }
}

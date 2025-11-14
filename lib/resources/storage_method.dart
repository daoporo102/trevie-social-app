import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageMethod {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  //adding image to firebase storage
  Future<String> uploadImageToStorage(
    String childName,
    Uint8List file,
    bool isPost,
  ) async {
    try {
      Reference ref = _storage
          .ref()
          .child(childName)
          .child(_auth.currentUser!.uid);

      if (isPost) {
        String id = const Uuid().v1();
        ref = ref.child(id);
      }

      UploadTask uploadTask = ref.putData(file);

    TaskSnapshot snap = await uploadTask;
    String downloadUrl = await snap.ref.getDownloadURL();
    return downloadUrl;
  }

  //Delete post's image in storage
  Future<void> deleteImageFromStorage(String imageUrl) async {
    try {
      // Validate the URL format
      if (!imageUrl.startsWith('gs://') && !imageUrl.startsWith('http')) {
        throw 'URL ảnh không hợp lệ: $imageUrl';
      }
      
      //get a reference 
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      throw 'Lỗi tải lên: ${e.message ?? e.code}';
    } catch (e) {
      throw 'Lỗi không xác định khi tải ảnh: $e';
    }
  }
}

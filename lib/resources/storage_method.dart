import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:uuid/uuid.dart';

class StorageMethod {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper để detect image type từ bytes
  String _detectImageType(Uint8List bytes) {
    // PNG signature: 89 50 4E 47
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }

    // JPEG signature: FF D8 FF
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }

    // Default to JPEG
    return 'image/jpeg';
  }

  //adding image to firebase storage
  Future<String> uploadImageToStorage(
    String childName,
    Uint8List file,
    bool isPost,
  ) async {
    try {
      // Validate size BEFORE upload
      if (file.length > 5 * 1024 * 1024) {
        throw 'Ảnh quá lớn, vui lòng chọn ảnh dưới 5MB';
      }

      Reference ref = _storage
          .ref()
          .child(childName)
          .child(_auth.currentUser!.uid);

      if (isPost) {
        String id = const Uuid().v1();
        ref = ref.child(id);
      }

      // Detect and set exactly the content type
      final contentType = _detectImageType(file);
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {'uploaded_by': 'flutter-app'},
      );

      UploadTask uploadTask = ref.putData(file, metadata);

      TaskSnapshot snap = await uploadTask;
      String downloadUrl = await snap.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      // Handle Firebase-specific errors
      if (e.code == 'unauthorized' || e.code == 'permission-denied') {
        throw 'Ảnh quá lớn hoặc không đúng định dạng. Vui lòng chọn ảnh dưới 5MB';
      } else if (e.code == 'retry-limit-exceeded') {
        throw 'Kết nối mạng không ổn định, vui lòng thử lại';
      }
      throw 'Lỗi tải lên: ${e.message ?? e.code}';
    } catch (e) {
      // Re-throw custom errors
      if (e.toString().contains('quá lớn')) {
        rethrow;
      }
      throw 'Lỗi không xác định khi tải ảnh: $e';
    }
  }

  // Upload multiple images to storage
  Future<List<String>> uploadMultipleImages(
    String childName,
    List<Uint8List> files,
    bool isPost,
  ) async {
    try {
      final startTime = DateTime.now();
      avoidPrint("Starting upload of ${files.length} images...");

      // Validate all files first
      for (var file in files) {
        if (file.length > 5 * 1024 * 1024) {
          throw 'Một hoặc nhiều ảnh quá lớn. Vui lòng chọn ảnh dưới 5MB';
        }
      }

      // Upload all images in parallel
      final uploadTasks = files.map(
        (file) => uploadImageToStorage(childName, file, isPost),
      );

      final downloadUrls = await Future.wait(uploadTasks);

      final duration = DateTime.now().difference(startTime);
      avoidPrint("Uploaded ${files.length} images in ${duration.inSeconds}s");

      return downloadUrls;
    } on FirebaseException catch (e) {
      if (e.code == 'unauthorized' || e.code == 'permission-denied') {
        throw 'Một hoặc nhiều ảnh không hợp lệ. Vui lòng chọn ảnh dưới 5MB';
      }
      throw 'Lỗi khi tải lên nhiều ảnh: ${e.message ?? e.code}';
    } catch (e) {
      // Re-throw custom errors
      if (e.toString().contains('quá lớn')) {
        rethrow;
      }
      throw 'Lỗi khi tải lên nhiều ảnh: $e';
    }
  }

  //Delete post's image in storage
  Future<void> deleteImageFromStorage(String imageUrl) async {
    try {
      // Validate the URL format
      if (!imageUrl.startsWith('gs://') && !imageUrl.startsWith('http')) {
        avoidPrint('URL ảnh không hợp lệ: $imageUrl');
        return;
      }

      //get a reference
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      throw 'Lỗi tải lên: ${e.message ?? e.code}';
    } catch (e) {
      avoidPrint('Lỗi xoá ảnh cũ: $e');
    }
  }

  // Delete multiple images from storage
  Future<void> deleteMultipleImagesFromStorage(List<String> imageUrls) async {
    try {
      List<Future<void>> deleteTasks = imageUrls.map((url) {
        return deleteImageFromStorage(url);
      }).toList();

      await Future.wait(deleteTasks);
    } catch (e) {
      avoidPrint('Lỗi khi xoá nhiều ảnh: $e');
    }
  }

  //update post's image to Storage
  Future<String> updateImageInStorage(
    String childName,
    Uint8List file,
    String existingImageUrl,
    bool isPost,
  ) async {
    try {
      // First, delete the existing image
      await deleteImageFromStorage(existingImageUrl);

      // Then, upload the new image
      String newImageUrl = await uploadImageToStorage(childName, file, isPost);

      return newImageUrl;
    } catch (e) {
      throw 'Lỗi khi cập nhật ảnh: $e';
    }
  }
}

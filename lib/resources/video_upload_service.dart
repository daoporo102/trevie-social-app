import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VideoUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add minimum duration constant
  static const int minVideoDurationSeconds = 1;
  static const int maxVideoDurationSeconds = 180; // 3 minutes

  /// Validate video before compression
  Future<String?> validateVideo(File videoFile) async {
    try {
      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();

      final duration = controller.value.duration;
      await controller.dispose();

      if (duration.inSeconds < minVideoDurationSeconds) {
        return 'Video phải dài ít nhất $minVideoDurationSeconds giây';
      }

      if (duration.inSeconds > maxVideoDurationSeconds) {
        return 'Video không được vượt quá ${maxVideoDurationSeconds ~/ 60} phút';
      }

      return null; // Valid
    } catch (e) {
      avoidPrint('Error validating video: $e');
      return 'Không thể đọc thông tin video';
    }
  }

  /// Compress video with better error handling
  Future<File?> compressVideo(File videoFile) async {
    try {
      // Validate first
      final validationError = await validateVideo(videoFile);
      if (validationError != null) {
        throw Exception(validationError);
      }

      avoidPrint('Starting video compression...');

      final info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
        frameRate: 30,
      );

      if (info == null || info.file == null) {
        avoidPrint('Compression failed, using original file');
        return videoFile; // Fallback to original
      }

      // Check if compressed file is valid
      if (await info.file!.length() < 1024) {
        avoidPrint('Compressed file too small, using original');
        return videoFile; // Fallback to original
      }

      avoidPrint('Video compressed successfully: ${info.file!.path}');
      avoidPrint('Original size: ${videoFile.lengthSync()} bytes');
      avoidPrint('Compressed size: ${info.file!.lengthSync()} bytes');

      return info.file;
    } catch (e) {
      avoidPrint('Error compressing video: $e');
      avoidPrint('Using original file as fallback');
      return videoFile; // Fallback to original
    }
  }

  // Upload compressed video to Firebase Storage
  Future<String> uploadVideoToStorage(File videoFile) async {
    try {
      // Validate size (max 50MB after compress)
      final fileSize = await videoFile.length();
      if (fileSize > 50 * 1024 * 1024) {
        throw 'Video quá lớn. Vui lòng chọn video dưới 50MB';
      }

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final String uid = _auth.currentUser!.uid;

      Reference ref = _storage.ref().child('videos').child(uid).child(fileName);

      // Upload with metadata
      final metadata = SettableMetadata(
        contentType: 'video/mp4',
        customMetadata: {
          'uploaded_by': 'flutter-app',
          'original_size': fileSize.toString(),
        },
      );

      avoidPrint('Uploading video to Firebase Storage...');
      UploadTask uploadTask = ref.putFile(videoFile, metadata);

      // Track progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        avoidPrint('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      TaskSnapshot snap = await uploadTask;
      String downloadUrl = await snap.ref.getDownloadURL();

      avoidPrint('Video uploaded successfully: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      if (e.code == 'unauthorized' || e.code == 'permission-denied') {
        throw 'Không có quyền tải video lên. Vui lòng đăng nhập lại';
      }
      throw 'Lỗi Firebase: ${e.message ?? e.code}';
    } catch (e) {
      throw 'Lỗi tải video: $e';
    }
  }

  // Get video thumbnail
  Future<Uint8List?> getVideoThumbnail(File videoFile) async {
    try {
      final thumbnail = await VideoCompress.getByteThumbnail(
        videoFile.path,
        quality: 80,
        position: -1, // Capture the middle frame of the video.
      );
      return thumbnail;
    } catch (e) {
      avoidPrint('Error getting video thumbnail: $e');
      return null;
    }
  }

  // Delete video from storage
  Future<void> deleteVideoFromStorage(String videoUrl) async {
    try {
      Reference ref = _storage.refFromURL(videoUrl);
      await ref.delete();
      avoidPrint('Video deleted from storage');
    } catch (e) {
      avoidPrint('Error deleting video: $e');
    }
  }

  // Cancel compression (cleanup)
  void cancelCompression() {
    if (!kIsWeb) {
      try {
        VideoCompress.cancelCompression();
      } catch (e) {
        avoidPrint('Error canceling compression: $e');
      }
    }
  }
}

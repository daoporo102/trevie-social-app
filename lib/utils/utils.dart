import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:social_media_app/widgets/custom_snack_bar.dart';

void displaySnackBar(String text, BuildContext context, SnackBarType type) {
  // Check if context is still valid
  if (!context.mounted) return;

  ScaffoldMessenger.of(
    context,
  ).showSnackBar(CustomSnackBar.buildSnackBar(text: text, type: type));
}

Future<Uint8List?> pickImage(ImageSource source) async {
  // Your image picking logic here
  final ImagePicker imagePicker = ImagePicker();
  final XFile? file = await imagePicker.pickImage(source: source);
  if (file == null) {
    avoidPrint("No image selected");
    return null;
  }
  return await file.readAsBytes();
}

void avoidPrint(String s) {
  if (kDebugMode) {
    print(s);
  }
}

String formatTimestamp(Timestamp timestamp) {
  final now = DateTime.now();
  final messageTime = timestamp.toDate();
  final difference = now.difference(messageTime);

  if (difference.inDays == 0) {
    // Today: show HH:mm
    return DateFormat('HH:mm', 'vi').format(messageTime);
  } else if (difference.inDays == 1 && now.day > messageTime.day) {
    // Yesterday
    return 'Hôm qua';
  } else if (difference.inDays < 7) {
    // Within a week: show day of the week
    return DateFormat('EEEE', 'vi').format(messageTime);
  } else {
    // Older: show dd/MM/yyyy
    return DateFormat('dd/MM/yyyy', 'vi').format(messageTime);
  }
}

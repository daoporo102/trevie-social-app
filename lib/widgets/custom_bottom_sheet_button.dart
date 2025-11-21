import 'package:flutter/material.dart';
import 'package:social_media_app/utils/colors.dart';

class CustomBottomSheetButton extends StatelessWidget {
  final Widget childCustomButton;
  final Widget childModalBottomSheet;
  const CustomBottomSheetButton({
    super.key,
    required this.childCustomButton,
    required this.childModalBottomSheet,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showModalBottomSheet(
          // Vital for full-screen or custom height bottom sheets
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: mobileBackgroundColor,
          // Dim the background less or change color
          barrierColor: primaryTextColor.withValues(alpha: 0.5),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
          ),
          context: context,
          builder: (_) {
            return Padding(
              // Push content up when keyboard opens
              padding: MediaQuery.of(context).viewInsets,
              child: childModalBottomSheet,
            );
          },
        );
      },
      icon: childCustomButton,
    );
  }
}

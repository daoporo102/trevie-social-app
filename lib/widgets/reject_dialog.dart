import 'package:flutter/material.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/widgets/custom_button.dart';

class RejectionDialog extends StatelessWidget {
  final String reason;
  final String title;
  final String description;
  final VoidCallback? onDismiss;

  const RejectionDialog({
    super.key,
    required this.reason,
    required this.title,
    required this.description,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: mobileBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with icon
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: errorBackgroundColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Description
            Text(
              description,
              style: TextStyle(fontSize: 16, color: primaryTextColor),
            ),
            const SizedBox(height: 16),

            // Reason container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: errorBackgroundColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: errorBackgroundColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: errorBackgroundColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: TextStyle(
                        color: errorBackgroundColor,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Helper text
            Text(
              'Vui lòng chỉnh sửa nội dung và thử lại.',
              style: TextStyle(fontSize: 14, color: secondaryColor),
            ),
            const SizedBox(height: 24),

            // Additional info
            Text(
              'Bạn có thể xem lại nội dung của mình ở màn cài đặt -> lịch sử vi phạm.',
              style: TextStyle(
                fontSize: 14,
                color: secondaryColor,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 24),

            // Action button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onDismiss?.call();
                },
                backgroundColor: appPrimaryColor,
                borderRadius: BorderRadius.circular(8),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Text(
                  'Đã hiểu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: onPrimaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Static method to show the dialog
  static Future<void> show(
    BuildContext context, {
    required String reason,
    String? title,
    String? description,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return RejectionDialog(
          reason: reason,
          title: title ?? 'Bài viết bị từ chối',
          description:
              description ?? 'Hệ thống đã phát hiện nội dung không phù hợp:',
          onDismiss: onDismiss,
        );
      },
    );
  }
}

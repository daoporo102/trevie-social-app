import 'package:flutter/material.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/widgets/custom_button.dart';

class RejectionDialog extends StatelessWidget {
  final String reason;
  final String title;
  final String description;
  final VoidCallback? onDismiss;
  final double? textScore;
  final double? imageScore;

  const RejectionDialog({
    super.key,
    required this.reason,
    required this.title,
    required this.description,
    this.onDismiss,
    this.textScore,
    this.imageScore,
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

            // AI Score Analysis
            if (textScore != null && textScore! > 0 ||
                imageScore != null && imageScore! > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (textScore != null && textScore! > 0) ...[
                    _buildScoreBadge("Điểm văn bản", textScore!),
                    const SizedBox(width: 12),
                  ],
                  if (imageScore != null && imageScore! > 0)
                    _buildScoreBadge("Điểm hình ảnh", imageScore!),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Helper text
            Text(
              'Vui lòng chỉnh sửa nội dung và thử lại.',
              style: TextStyle(fontSize: 14, color: secondaryColor),
            ),
            const SizedBox(height: 24),

            // Additional info
            Text(
              'Bạn có thể xem lại nội dung vi phạm của mình ở màn hình cài đặt -> lịch sử vi phạm.',
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

  // Widget hiển thị điểm số
  Widget _buildScoreBadge(String title, double score) {
    // Màu sắc dựa trên mức độ nguy hiểm
    Color color = errorBackgroundColor;
    if (score > 0.8) {
      color = errorBackgroundColor;
    } else if (score > 0.5) {
      color = Colors.orange;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: secondaryColor, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Text(
            "${(score * 100).toStringAsFixed(2)}%",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  /// Static method to show the dialog
  static Future<void> show(
    BuildContext context, {
    required String reason,
    String? title,
    String? description,
    VoidCallback? onDismiss,
    double? aiConfidence,
    double? textScore,
    double? imageScore,
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
          textScore: textScore,
          imageScore: imageScore,
        );
      },
    );
  }
}

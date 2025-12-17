import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:social_media_app/models/violation_log.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';

class ViolationsHistoryScreen extends StatelessWidget {
  const ViolationsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: const Text('Lịch sử vi phạm'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('violation_logs')
            .where('uid', isEqualTo: currentUserUid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: customCircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Hồ sơ của bạn rất sạch!',
                    style: TextStyle(color: primaryTextColor, fontSize: 18),
                  ),
                  Text(
                    'Chưa ghi nhận vi phạm nào.',
                    style: TextStyle(color: secondaryColor),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              ViolationLog log = ViolationLog.fromSnap(
                snapshot.data!.docs[index],
              );
              return _buildLogCard(context, log);
            },
          );
        },
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, ViolationLog log) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(log.createdAt);

    // Icon dựa trên Action
    IconData actionIcon;
    String actionText;
    if (log.actionType == 'update') {
      actionIcon = Icons.edit_note;
      actionText = "Cập nhật bài";
    } else if (log.actionType == 'create') {
      actionIcon = Icons.post_add;
      actionText = "Đăng bài mới";
    } else if (log.actionType == 'reshare') {
      actionIcon = Icons.share;
      actionText = "Chia sẻ bài viết";
    } else {
      actionIcon = Icons.error_outline;
      actionText = "Hành động khác";
    }

    return Card(
      color: mobileBackgroundColor,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          child: Icon(actionIcon, color: Colors.red),
        ),
        title: Text(
          log.reason,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "$dateStr • $actionText",
              style: const TextStyle(color: secondaryColor, fontSize: 12),
            ),
            const SizedBox(height: 6),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: secondaryColor.withValues(alpha: 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. PHẦN ĐIỂM SỐ CHI TIẾT
                const Text(
                  "Phân tích AI:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildScoreBadge("Text Score", log.textScore),
                    const SizedBox(width: 12),
                    _buildScoreBadge("Image Score", log.imageScore),
                  ],
                ),
                const Divider(height: 24),

                // 2. NỘI DUNG VI PHẠM
                const Text(
                  "Nội dung bị chặn:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 8),

                if (log.toxicText != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log.toxicText!,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                if (log.toxicImageUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      log.toxicImageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Text(
                        "Ảnh đã bị xóa hoặc không tải được",
                        style: TextStyle(color: secondaryColor),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Xử lý bởi: ${log.moderatedBy}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị điểm số
  Widget _buildScoreBadge(String title, double score) {
    // Màu sắc dựa trên mức độ nguy hiểm
    Color color = Colors.green;
    if (score > 0.8) {
      color = Colors.red;
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
            color: color.withValues(alpha: 0.1),
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
}

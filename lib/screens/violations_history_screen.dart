import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/widgets/post_card.dart';

class ViolationsHistoryScreen extends StatelessWidget {
  const ViolationsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUserrOrNull;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: mobileBackgroundColor,
          title: const Text('Lịch sử vi phạm'),
          centerTitle: false,
        ),
        body: customCircularProgressIndicator(),
      );
    }

    final width = MediaQuery.of(context).size.width;

    // Query for rejected posts by current user
    final rejectedPostsStream = FirebaseFirestore.instance
        .collection('posts')
        .where('uid', isEqualTo: user.uid)
        .where('status', isEqualTo: 'rejected')
        .orderBy('lastDateModified', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: width > webScreenSize
            ? webBackgroundColor
            : mobileBackgroundColor,
        title: const Text('Lịch sử vi phạm'),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: rejectedPostsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return customCircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: errorBackgroundColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Có lỗi xảy ra khi tải dữ liệu',
                      style: TextStyle(
                        fontSize: 16,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Không có bài viết vi phạm',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tất cả bài đăng của bạn đều tuân thủ tiêu chuẩn cộng đồng',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: width > webScreenSize ? width * 0.3 : 0,
              vertical: 8,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              return Container(
                margin: EdgeInsets.symmetric(
                  horizontal: width > webScreenSize ? 0 : 0,
                  vertical: 4,
                ),
                child: PostCard(snap: doc),
              );
            },
          );
        },
      ),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/screens/profile_screen.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/widgets/post_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  bool isShowUsers = false;

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
  }

  // Search Users and Posts
  Future<Map<String, dynamic>> _searchUserAndPosts(
    String query,
    String? currentUid,
  ) async {
    if (query.isEmpty) {
      return {'users': [], 'posts': []};
    }

    // Convert query to lowercase for case-insensitive search
    final lowerQuery = query.toLowerCase();

    // Search users
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .get();

    // Filter users by displayName (case-insensitive) and exclude current user
    final users = usersSnapshot.docs.where((doc) {
      final data = doc.data();
      final displayName = (data['displayName'] as String? ?? '').toLowerCase();
      final username = (data['username'] as String? ?? '').toLowerCase();
      final uid = data['uid'] as String?;

      // Exclude current user and check if displayName or username contains query
      return uid != currentUid &&
          (displayName.contains(lowerQuery) || username.contains(lowerQuery));
    }).toList();

    // Get all posts and filter in memory (for case-insensitive search)
    final postsSnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .get();

    // Filter posts by postText (case-insensitive)
    final posts = postsSnapshot.docs.where((doc) {
      final data = doc.data();
      final postText = (data['postText'] as String? ?? '').toLowerCase();

      // Check if postText contains query
      return postText.contains(lowerQuery);
    }).toList();

    return {'users': users, 'posts': posts};
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: width > webScreenSize
          ? AppBar(
              backgroundColor: mobileBackgroundColor,
              title: Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: width * 0.3,
                  child: TextFormField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Tìm kiếm người dùng hoặc bài đăng ở đây',
                      hintStyle: TextStyle(color: primaryTextColor),
                      fillColor: textFieldBackgroundColor,
                      labelStyle: TextStyle(color: secondaryColor),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
                    ),
                    cursorColor: appPrimaryColor,
                    onFieldSubmitted: (String _) {
                      setState(() {
                        isShowUsers = true;
                      });
                      // avoidPrint(value);
                    },
                  ),
                ),
              ),
            )
          : AppBar(
              backgroundColor: mobileBackgroundColor,
              title: TextFormField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Tìm kiếm người dùng hoặc bài đăng ở đây',
                  hintStyle: TextStyle(color: primaryTextColor),
                  fillColor: textFieldBackgroundColor,
                  labelStyle: TextStyle(color: secondaryColor),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                ),
                cursorColor: appPrimaryColor,
                onFieldSubmitted: (String _) {
                  setState(() {
                    isShowUsers = true;
                  });
                  // avoidPrint(value);
                },
              ),
            ),
      body: isShowUsers
          ? FutureBuilder<Map<String, dynamic>>(
              // Search for users whose displayName starts with the search query
              future: _searchUserAndPosts(searchController.text, currentUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return customCircularProgressIndicator();
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: Text('Không tìm thấy kết quả nào'),
                  );
                }

                final users = snapshot.data!['users'] as List<DocumentSnapshot>;
                final posts = snapshot.data!['posts'] as List<DocumentSnapshot>;

                if (users.isEmpty && posts.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy kết quả nào'),
                  );
                }

                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width > webScreenSize ? width * 0.3 : 16,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Section
                        if (users.isNotEmpty) ...[
                          Text(
                            'Người dùng (${users.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                          SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final userData =
                                  users[index].data() as Map<String, dynamic>;
                              final uid = userData['uid'] as String;
                              final displayName =
                                  userData['displayName'] as String;
                              final photoUrl = userData['photoUrl'] as String;
                              return InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProfileScreen(uid: uid),
                                    ),
                                  );
                                },
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: photoUrl.isNotEmpty
                                        ? NetworkImage(photoUrl)
                                        : null,
                                    radius: 24,
                                  ),
                                  title: Text(
                                    displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    color: secondaryColor,
                                    size: 16,
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 16),
                          Divider(color: secondaryColor),
                          SizedBox(height: 16),
                        ],

                        // Post Section with StreamBuilder for real-time update
                        if (posts.isNotEmpty) ...[
                          Text(
                            'Bài đăng (${posts.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                          SizedBox(height: 12),
                          ...posts.map((postDoc) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('posts')
                                    .doc(postDoc.id)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return PostCard(snap: postDoc);
                                  }
                                  return PostCard(snap: snapshot.data!);
                                },
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                );
              },
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 80, color: secondaryColor),
                  SizedBox(height: 16),
                  Text(
                    'Tìm kiếm người dùng hoặc bài đăng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

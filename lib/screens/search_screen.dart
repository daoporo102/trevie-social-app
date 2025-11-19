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

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: TextFormField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Tìm kiếm người dùng hoặc bài đăng ở đây',
            hintStyle: TextStyle(color: primaryTextColor),
            fillColor: textFieldBackgroundColor,
            labelStyle: TextStyle(color: secondaryColor),
            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
              future: searchUserAndPosts(searchController.text, currentUid),
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

                        // Post Section
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
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: posts.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: PostCard(snap: posts[index]),
                              );
                            },
                          ),
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

  // Search Users and Posts
  Future<Map<String, dynamic>> searchUserAndPosts(
    String query,
    String? currentUid,
  ) async {
    // Search users
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('displayName')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .get();

    // Filter out the current user from the results
    final users = usersSnapshot.docs
        .where((d) => d.data()['uid'] != currentUid)
        .toList();

    // Search posts by postText
    final postsSnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .orderBy('postText')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .get();

    return {'users': users, 'posts': postsSnapshot.docs};
  }
}

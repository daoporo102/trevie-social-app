import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/follow_button.dart';
import 'package:social_media_app/widgets/post_card.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> userData = {};
  var postLen = 0;
  var followers = 0;
  var following = 0;
  bool isFollowing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Fetch user data from Firestore
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      if (!userSnap.exists || userSnap.data() == null) {
        // User not found -> reset values and stop loading
        if (!mounted) return;
        setState(() {
          userData = {};
          postLen = 0;
          followers = 0;
          following = 0;
          isFollowing = false;
          _isLoading = false;
        });
        return;
      }

      final data = userSnap.data();
      // Count posts for the viewed profile
      var postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: widget.uid)
          .get();

      final currentUid = FirebaseAuth.instance.currentUser?.uid;

      if (!mounted) return;
      setState(() {
        userData = data!;
        postLen = postSnap.docs.length;
        followers = (data['followers'] as List?)?.length ?? 0;
        following = (data['following'] as List?)?.length ?? 0;
        isFollowing = ((data['followers'] as List?) ?? const []).contains(
          currentUid,
        );
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) showSnackBar(e.toString(), context);
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (userData['displayName'] as String?) ?? 'Loading...';
    final photoUrl = (userData['photoUrl'] as String?) ?? '';
    final bio = (userData['bio'] as String?) ?? 'Chưa có tiểu sử';
    final postStream = FirebaseFirestore.instance
        .collection('posts')
        .where('uid', isEqualTo: widget.uid)
        .orderBy('datePublished', descending: true)
        .snapshots();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: Text(displayName),
        centerTitle: false,
        bottom: _isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3),
              )
            : null,
      ),
      body: CustomScrollView(
        slivers: [
          //Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: secondaryColor,
                    backgroundImage: photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                    radius: 40,
                    child: photoUrl.isEmpty
                        ? Icon(Icons.person, size: 40, color: primaryTextColor)
                        : null,
                  ),
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      displayName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(alignment: Alignment.center, child: Text(bio)),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                buildStatColumn(postLen, 'bài đăng'),
                                buildStatColumn(followers, 'người theo dõi'),
                                buildStatColumn(following, 'đang theo dõi'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                FirebaseAuth.instance.currentUser!.uid ==
                                        widget.uid
                                    ? FollowButton(
                                        backgroundColor: mobileBackgroundColor,
                                        borderColor: secondaryColor,
                                        text: 'Chỉnh sửa hồ sơ',
                                        textColor: primaryTextColor,
                                        function: () {},
                                      )
                                    : isFollowing
                                    ? FollowButton(
                                        backgroundColor: mobileBackgroundColor,
                                        borderColor: secondaryColor,
                                        text: 'Huỷ theo dõi',
                                        textColor: primaryTextColor,
                                        function: () {},
                                      )
                                    : FollowButton(
                                        backgroundColor: mobileBackgroundColor,
                                        borderColor: appPrimaryColor,
                                        text: 'Theo dõi',
                                        textColor: appPrimaryColor,
                                        function: () {},
                                      ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          //Posts Grid (live)
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: postStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Lỗi: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting &&
                  (snapshot.data?.docs.isEmpty ?? true)) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: const Center(
                      child: Text('Bạn chưa có bài đăng nào'),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final doc = docs[index];
                  return PostCard(snap: doc);
                }, childCount: docs.length),
              );
            },
          ),
        ],
      ),
    );
  }

  Column buildStatColumn(int num, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          num.toString(),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: const EdgeInsets.only(top: 2),
          child: Text(
            label,
            style: TextStyle(
              color: secondaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

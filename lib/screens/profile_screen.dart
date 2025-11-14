import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/resources/firestore_method.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/custom_snack_bar.dart';
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
      if (mounted) {
        displaySnackBar(e.toString(), context, SnackBarType.error);
      }
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

    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: width > webScreenSize
          ? null
          : AppBar(
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
              // padding: const EdgeInsets.all(16.0),
              padding: EdgeInsets.symmetric(
                horizontal: width > webScreenSize ? width * 0.3 : 0,
                vertical: width > webScreenSize ? 15 : 0,
              ),
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
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // Never exceed the available width; cap at 420 on large screens
                                final double buttonWidth =
                                    constraints.maxWidth > 420
                                    ? 420
                                    : constraints.maxWidth;

                                Widget btn;
                                if (FirebaseAuth.instance.currentUser!.uid ==
                                    widget.uid) {
                                  btn = FollowButton(
                                    backgroundColor: mobileBackgroundColor,
                                    borderColor: secondaryColor,
                                    text: 'Chỉnh sửa hồ sơ',
                                    textColor: primaryTextColor,
                                    function: () {},
                                  );
                                } else if (isFollowing) {
                                  btn = FollowButton(
                                    backgroundColor: mobileBackgroundColor,
                                    borderColor: secondaryColor,
                                    text: 'Huỷ theo dõi',
                                    textColor: primaryTextColor,
                                    function: () async {
                                      //unfollow user
                                      await FirestoreMethod().followUser(
                                        FirebaseAuth.instance.currentUser!.uid,
                                        userData['uid'],
                                      );

                                      setState(() {
                                        isFollowing = false;
                                        followers--;
                                      });
                                    },
                                  );
                                } else {
                                  btn = FollowButton(
                                    backgroundColor: mobileBackgroundColor,
                                    borderColor: appPrimaryColor,
                                    text: 'Theo dõi',
                                    textColor: appPrimaryColor,
                                    function: () async {
                                      //follow user
                                      await FirestoreMethod().followUser(
                                        FirebaseAuth.instance.currentUser!.uid,
                                        userData['uid'],
                                      );

                                      setState(() {
                                        isFollowing = true;
                                        followers++;
                                      });
                                    },
                                  );
                                }
                                return Align(
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: buttonWidth,
                                    height: 80,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: btn,
                                    ),
                                  ),
                                );
                              },
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
                  return Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: width > webScreenSize ? width * 0.3 : 0,
                      vertical: width > webScreenSize ? 15 : 0,
                    ),
                    child: PostCard(snap: doc),
                  );
                }, childCount: docs.length),
              );
            },
          ),
        ],
      ),
    );
  }

  Expanded buildStatColumn(int num, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            num.toString(),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: secondaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

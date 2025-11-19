import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/firestore_method.dart';
import 'package:social_media_app/screens/edit_profile_screen.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/custom_snack_bar.dart';
import 'package:social_media_app/widgets/custom_text_button.dart';
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
    final displayName = (userData['displayName'] as String?) ?? 'Đang tải...';
    final photoUrl = (userData['photoUrl'] as String?) ?? '';
    final bio = (userData['bio'] as String?) ?? 'Chưa có tiểu sử';
    final dateOfBirth = (userData['dateOfBirth'] as Timestamp?)?.toDate();
    final postStream = FirebaseFirestore.instance
        .collection('posts')
        .where('uid', isEqualTo: widget.uid)
        .orderBy('datePublished', descending: true)
        .snapshots();

    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      // Hide AppBar on web, show on mobile
      appBar: width > webScreenSize
          ? null
          : AppBar(
              backgroundColor: mobileBackgroundColor,
              title: Text(displayName),
              centerTitle: false,
              bottom: _isLoading
                  ? PreferredSize(
                      preferredSize: Size.fromHeight(3),
                      child: customLinearProgressIndicator(),
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
                  // Add back button for Web layout
                  if (width > webScreenSize &&
                      FirebaseAuth.instance.currentUser!.uid != widget.uid)
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back, color: primaryTextColor),
                              SizedBox(width: 8),
                              Text('Quay lại'),
                            ],
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  CircleAvatar(
                    backgroundColor: secondaryColor,
                    radius: 40,
                    child: photoUrl.isEmpty
                        ? Icon(Icons.person, size: 40, color: primaryTextColor)
                        : ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: photoUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  customCircularProgressIndicator(),
                              errorWidget: (context, url, error) => Icon(
                                Icons.person,
                                size: 40,
                                color: primaryTextColor,
                              ),
                            ),
                          ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: primaryTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    alignment: Alignment.center,
                    child: Text('Tiểu sử: $bio'),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    alignment: Alignment.center,
                    child: dateOfBirth != null
                        ? Text(
                            'Ngày sinh: ${dateOfBirth.day}/${dateOfBirth.month}/${dateOfBirth.year}',
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 8),
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
                                  btn = CustomTextButton(
                                    backgroundColor:
                                        secondaryButtonBackgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                    overlayColor: appPrimaryColor,
                                    onPressed: () async {
                                      // Wait for edit screen to close before refreshing
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditProfileScreen(),
                                        ),
                                      );
                                      // Now these run AFTER returning from edit screen
                                      if (mounted) {
                                        await getData();
                                        await Provider.of<UserProvider>(
                                          context,
                                          listen: false,
                                        ).refreshUser();
                                      }
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,

                                        children: [
                                          Icon(
                                            Icons.edit_outlined,
                                            color: primaryTextColor,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Chỉnh sửa hồ sơ',
                                            style: TextStyle(
                                              color: primaryTextColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else if (isFollowing) {
                                  btn = CustomTextButton(
                                    onPressed: () async {
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
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.person_remove_alt_1_outlined,
                                            color: primaryTextColor,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Huỷ theo dõi',
                                            style: TextStyle(
                                              color: primaryTextColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else {
                                  btn = CustomTextButton(
                                    backgroundColor: appPrimaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                    overlayColor: onPrimaryColor,
                                    onPressed: () async {
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
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.person_add_alt_1_outlined,
                                            color: onPrimaryColor,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Theo dõi',
                                            style: TextStyle(
                                              color: onPrimaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
                    child: customCircularProgressIndicator(),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: const Center(child: Text('Chưa có bài đăng nào')),
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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/firestore_method.dart';
import 'package:social_media_app/screens/chat/chat_screen.dart';
import 'package:social_media_app/screens/edit_profile_screen.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/custom_snack_bar.dart';
import 'package:social_media_app/widgets/custom_button.dart';
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
      // Count posts for the viewed profile (only active posts)
      var postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: widget.uid)
          .where('status', isEqualTo: 'active')
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
        displaySnackBar(
          "Có lỗi xảy ra, vui lòng thử lại sau",
          context,
          SnackBarType.error,
        );
        avoidPrint("Error to Display Profile Screen ${e.toString()}");
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (userData['displayName'] as String?) ?? 'Đang tải...';
    final role = userData['role'] as String?;
    final photoUrl = (userData['photoUrl'] as String?) ?? '';
    final bio = (userData['bio'] as String?) == '' || (userData['bio'] == null)
        ? 'Chưa có tiểu sử'
        : userData['bio'];
    final dateOfBirth = (userData['dateOfBirth'] as Timestamp?)?.toDate();

    // Determine if the profile belongs to the current user
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    // Check if the current user is viewing their own profile
    final isMe = currentUserUid == widget.uid;

    // Refresh the user provider
    final refreshProvider = Provider.of<UserProvider>(
      context,
      listen: false,
    ).refreshUser();

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('posts')
        .where('uid', isEqualTo: widget.uid);

    // If it's the current user
    if (isMe) {
      query = query.where('status', whereIn: ['active', 'processing']);
    }
    // If it's another user
    else {
      query = query.where('status', isEqualTo: 'active');
    }

    final postStream = query
        .orderBy('lastDateModified', descending: true)
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
                  if (role == "admin") ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: appPrimaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Quản trị viên',
                          style: TextStyle(
                            color: appPrimaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Container(alignment: Alignment.center, child: Text('$bio')),
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

                                if (isMe) {
                                  // Display Edit Profile button for own profile
                                  return Align(
                                    alignment: Alignment.center,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 50,
                                      ),
                                      child: SizedBox(
                                        width: buttonWidth,
                                        height: 56,
                                        child: CustomButton(
                                          backgroundColor: width > webScreenSize
                                              ? webBackgroundColor
                                              : mobileBackgroundColor,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          overlayColor: appPrimaryColor,
                                          hasBorder: true,
                                          onPressed: () async {
                                            // 1. Get context-dependent values FIRST (before any await)
                                            final userProvider =
                                                Provider.of<UserProvider>(
                                                  context,
                                                  listen: false,
                                                );

                                            // 2. do async operations
                                            await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EditProfileScreen(),
                                              ),
                                            );

                                            //3. Check mounted after earch asysnc gap
                                            if (!mounted) return;

                                            await getData();

                                            if (!mounted) return;

                                            //4. Use stored references (no context access)
                                            await userProvider.refreshUser();
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.edit_outlined,
                                                  color: primaryTextColor,
                                                  size: 20,
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
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                // Display Follow/Unfollow and Message buttons for other users
                                return Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 50,
                                      ),
                                    child: SizedBox(
                                      width: buttonWidth,
                                      height: 50,
                                      child: Row(
                                        children: [
                                          // Follow/Unfollow button
                                          Expanded(
                                            child: isFollowing
                                                ? CustomButton(
                                                    // Unfollow button
                                                    backgroundColor:
                                                        width > webScreenSize
                                                        ? webBackgroundColor
                                                        : mobileBackgroundColor,
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                    overlayColor: appPrimaryColor,
                                                    hasBorder: true,
                                                    onPressed: () async {
                                                      await FirestoreMethod()
                                                          .followUser(
                                                            currentUserUid!,
                                                            widget.uid,
                                                          );
                                    
                                                      refreshProvider;
                                    
                                                      if (!mounted) return;
                                                      setState(() {
                                                        isFollowing = false;
                                                        followers--;
                                                      });
                                                    },
                                                    child: Text(
                                                      'Đang theo dõi',
                                                      style: TextStyle(
                                                        color: primaryTextColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  )
                                                : CustomButton(
                                                    // Follow button
                                                    backgroundColor:
                                                        appPrimaryColor,
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                    overlayColor: onPrimaryColor,
                                                    hasBorder: false,
                                                    onPressed: () async {
                                                      await FirestoreMethod()
                                                          .followUser(
                                                            currentUserUid!,
                                                            widget.uid,
                                                          );
                                    
                                                      refreshProvider;
                                    
                                                      if (!mounted) return;
                                                      setState(() {
                                                        isFollowing = true;
                                                        followers++;
                                                      });
                                                    },
                                                    child: Text(
                                                      'Theo dõi',
                                                      style: TextStyle(
                                                        color: onPrimaryColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Message button
                                          Expanded(
                                            child: CustomButton(
                                              backgroundColor:
                                                  width > webScreenSize
                                                  ? webBackgroundColor
                                                  : mobileBackgroundColor,
                                              borderRadius: BorderRadius.circular(
                                                8,
                                              ),
                                              overlayColor: appPrimaryColor,
                                              hasBorder: true,
                                              onPressed: () {
                                                // Calculate chat room ID 1-1
                                                List<String> ids = [
                                                  currentUserUid!,
                                                  widget.uid,
                                                ];
                                                ids.sort();
                                                String oneToOneChatId = ids.join(
                                                  "_",
                                                );
                                    
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ChatScreen(
                                                          chatRoomId:
                                                              oneToOneChatId,
                                                          receiverId: widget.uid,
                                                          name: displayName,
                                                          photoUrl: photoUrl,
                                                          isGroup: false,
                                                        ),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                'Nhắn tin',
                                                style: TextStyle(
                                                  color: primaryTextColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
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
                  final docData = doc.data();
                  final status = docData['status'] as String?;
                  final isProcessing = status == 'processing';

                  return Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: width > webScreenSize ? width * 0.3 : 0,
                      vertical: width > webScreenSize ? 15 : 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Show processing indicator overlay if status is 'processing'
                        Stack(
                          children: [
                            PostCard(snap: doc),

                            // Processing overlay (only for current user's own posts)
                            if (isProcessing && isMe)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: mobileBackgroundColor,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          customCircularProgressIndicator(),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Đang kiểm tra nội dung...',
                                            style: TextStyle(
                                              color: primaryTextColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Bài đăng của bạn đang được hệ thống AI kiểm duyệt',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: secondaryColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        if (width <= webScreenSize)
                          const Divider(color: secondaryColor, height: 1),
                      ],
                    ),
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

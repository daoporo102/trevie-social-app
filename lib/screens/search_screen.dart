import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/screens/profile_screen.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';

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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: TextFormField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Tìm kiếm người dùng',
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
          ? FutureBuilder(
              // Search for users whose displayName starts with the search query
              future: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('displayName')
                  .startAt([searchController.text])
                  .endAt(['${searchController.text}\uf8ff'])
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return customCircularProgressIndicator();
                }

                // Filter out the current user from the results
                final docs = snapshot.data!.docs
                    .where((d) => d.data()['uid'] != currentUid)
                    .toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy người dùng nào'),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final uid = data['uid'] as String;
                    final displayName = (data['displayName'] as String);
                    final photoUrl = data['photoUrl'] as String?;

                    return InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(uid: uid),
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: photoUrl!.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          radius: 16,
                          backgroundColor: secondaryColor,
                        ),
                        title: Text(displayName),
                      ),
                    );
                  },
                );
              },
            )
          : const Center(child: Text('Tìm kiếm người dùng bằng tên của họ')),
    );
  }
}

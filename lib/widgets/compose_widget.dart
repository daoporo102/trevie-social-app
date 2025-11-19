import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/screens/add_post_screen.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/widgets/custom_text_button.dart';

class ComposePostCard extends StatelessWidget {
  const ComposePostCard({super.key});

  void _goToCreatePost(BuildContext context) {
    // Navigate to the post creation screen
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddPostScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUserrOrNull; // nullable getter
    if (user == null) {
      return customCircularProgressIndicator();
    }

    return Card(
      color: onPrimaryColor,
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: width > webScreenSize
          ? null
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: width > webScreenSize
            ? const EdgeInsets.fromLTRB(24, 10, 24, 8)
            : const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CircleAvatar(backgroundImage: NetworkImage(user.photoUrl)),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextButton(
                    onPressed: () => _goToCreatePost(context),
                    backgroundColor: textFieldBackgroundColor,
                    overlayColor: appPrimaryColor,
                    borderRadius: BorderRadius.circular(16),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.mode_edit_outline_outlined,
                          color: primaryTextColor,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            "Bạn đang nghĩ gì?",
                            style: TextStyle(
                              fontSize: 16,
                              color: primaryTextColor,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

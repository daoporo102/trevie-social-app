import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/screens/add_post_screen.dart';
import 'package:social_media_app/utils/colors.dart';

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
    // final User user = Provider.of<UserProvider>(context).getUser;
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUserrOrNull; // nullable getter
     if (user == null) {
    return const Center(child: CircularProgressIndicator());
  }

    return Card(
      color: onPrimaryColor,
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CircleAvatar(backgroundImage: NetworkImage(user.photoUrl)),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.pressed)) {
                          return textFieldBackgroundColor.withValues(
                            alpha: 0.85,
                          );
                        }
                        if (states.contains(WidgetState.hovered)) {
                          return textFieldBackgroundColor.withValues(
                            alpha: 0.95,
                          );
                        }
                        return textFieldBackgroundColor;
                      }),
                      foregroundColor: WidgetStateProperty.all(
                        primaryTextColor,
                      ),
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered) ||
                            states.contains(WidgetState.pressed)) {
                          return appPrimaryColor.withValues(alpha: 0.08);
                        }
                        return Colors.transparent;
                      }),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                    ),
                    onPressed: () => _goToCreatePost(context),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.mode_edit_outline_outlined,
                          color: primaryTextColor,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Bạn đang nghĩ gì?",
                          style: TextStyle(
                            fontSize: 16,
                            color: primaryTextColor,
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

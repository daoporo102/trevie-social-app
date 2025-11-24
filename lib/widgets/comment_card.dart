import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/firestore_method.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/custom_bottom_sheet_button.dart';
import 'package:social_media_app/widgets/custom_button.dart';
import 'package:social_media_app/widgets/custom_icon_button.dart';
import 'package:social_media_app/widgets/custom_snack_bar.dart';

class CommentCard extends StatefulWidget {
  final snap;
  final String postId;
  const CommentCard({super.key, required this.snap, required this.postId});

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  Future<void> _deleteComments(BuildContext context) async {
    try {
      final User? user = Provider.of<UserProvider>(
        context,
        listen: false,
      ).getUserrOrNull;

      if (user == null) {
        if (context.mounted) {
          Navigator.of(context).pop();
          displaySnackBar(
            'Không tìm thấy thông tin người dùng',
            context,
            SnackBarType.error,
          );
        }
        return;
      }

      String res = await FirestoreMethod().deleteComment(
        widget.postId,
        widget.snap['commentId'],
      );

      if (!context.mounted) return; // Check before any UI operation

      Navigator.of(context).pop(); // Close the bottom sheet

      if (context.mounted && res == 'success') {
        displaySnackBar("Đã xoá bình luận", context, SnackBarType.success);
      } else {
        if (context.mounted) {
          avoidPrint("Failed to delete comment: $res");
          displaySnackBar(
            "Xoá bình luận thất bại: $res",
            context,
            SnackBarType.error,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        avoidPrint("Error to delete comment: ${e.toString()}");

        if (!context.mounted) return; // Check before UI operation

        Navigator.of(context).pop(); // Close dialog if still open

        displaySnackBar(
          "Xoá bình luận thất bại, vui lòng thử lại sau!",
          context,
          SnackBarType.error,
        );
      }
    }
  }

  Future<void> _showEditCommentInput(BuildContext context) async {
    TextEditingController commentController = TextEditingController(
      text: widget.snap['commentText'],
    );

    showModalBottomSheet(
      useSafeArea: true,
      backgroundColor: mobileBackgroundColor,
      // Dim the background less or change color
      barrierColor: primaryTextColor.withValues(alpha: 0.5),
      context: context,
      // // push sheet up when keyboard opens
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16.0,
            right: 16.0,
            top: 16.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: commentController,
                // Allow multiple lines
                maxLines: null,
                // autoFocus the input field when dialog opens
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Chỉnh sửa bình luận',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Huỷ', style: TextStyle(color: secondaryColor)),
                  ),
                  CustomButton(
                    onPressed: () async {
                      String newCommentText = commentController.text.trim();
                      if (newCommentText.isNotEmpty) {
                        await FirestoreMethod().updateComment(
                          widget.postId,
                          widget.snap['commentId'],
                          newCommentText,
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          displaySnackBar(
                            'Đã cập nhật bình luận',
                            context,
                            SnackBarType.success,
                          );
                          commentController.clear();
                        }
                      } else {
                        if (context.mounted) {
                          displaySnackBar(
                            'Bình luận không được để trống',
                            context,
                            SnackBarType.error,
                          );
                        }
                      }
                    },
                    child: Text('Lưu', style: TextStyle(color: onPrimaryColor)),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = Provider.of<UserProvider>(context).getUserrOrNull;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: secondaryColor,
            child:
                (widget.snap['profilePic'] != null &&
                    widget.snap['profilePic'].toString().isNotEmpty)
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: widget.snap['profilePic'],
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          customCircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(
                        Icons.error_outline_outlined,
                        size: 16,
                        color: primaryTextColor,
                      ),
                    ),
                  )
                : const Icon(Icons.person, size: 16, color: primaryTextColor),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: widget.snap['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                        WidgetSpan(
                          child: SizedBox(width: 8),
                          alignment: PlaceholderAlignment.middle,
                        ),
                        TextSpan(
                          text: DateFormat.yMMMd().add_jm().format(
                            widget.snap['lastDateModified'].toDate(),
                          ),
                          style: TextStyle(color: secondaryColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            ' ${widget.snap['commentText']}',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, top: 4.0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.favorite_border,
                            size: 16,
                            color: secondaryColor,
                          ),
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '0 thích',
                            style: TextStyle(
                              color: secondaryColor,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.reply,
                            size: 16,
                            color: secondaryColor,
                          ),
                        ),
                        SizedBox(width: 8),
                        CustomBottomSheetButton(
                          childCustomButton: Icon(
                            Icons.more_horiz,
                            size: 16,
                            color: secondaryColor,
                          ),
                          childModalBottomSheet: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (user!.uid == widget.snap['uid']) ...[
                                CustomIconButton(
                                  text: 'Xoá bình luận',
                                  icon: Icons.delete_outlined,
                                  onPress: () async {
                                    await _deleteComments(context);
                                  },
                                ),
                                CustomIconButton(
                                  text: 'Chỉnh sửa bình luận',
                                  icon: Icons.edit_outlined,
                                  onPress: () async {
                                    Navigator.of(context).pop();
                                    await _showEditCommentInput(context);
                                  },
                                ),
                              ] else ...[
                                CustomIconButton(
                                  text: 'Báo cáo bình luận',
                                  icon: Icons.report_outlined,
                                  onPress: () {},
                                ),
                              ],
                              CustomIconButton(
                                text: 'Huỷ',
                                icon: Icons.cancel_outlined,
                                onPress: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

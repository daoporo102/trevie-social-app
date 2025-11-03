import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:social_media_app/utils/colors.dart';

class CommentCard extends StatefulWidget {
  final snap;
  const CommentCard({super.key, required this.snap});

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(widget.snap['profilePic']),
            radius: 16,
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
                          text: DateFormat.yMMMd().format(
                            widget.snap['datePublished'].toDate(),
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
                        Text(
                          ' ${widget.snap['text']}',
                          style: TextStyle(fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 16,
                          color: secondaryColor,
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Phản hồi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: secondaryColor,
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

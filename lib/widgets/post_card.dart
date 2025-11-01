import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:social_media_app/utils/colors.dart';

class PostCard extends StatelessWidget {
  final snap;
  const PostCard({super.key, required this.snap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: mobileBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          //HEADER SECTION OF THE POST
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 16,
            ).copyWith(right: 0),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(snap['profImage']),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              snap['displayName'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat.yMMMd().format(
                                snap['datePublished'].toDate(),
                              ),
                              style: TextStyle(
                                color: secondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: ListView(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shrinkWrap: true,
                              children: ['Delete', 'Edit']
                                  .map(
                                    (e) => InkWell(
                                      onTap: () {},
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 16,
                                        ),
                                        child: Text(e),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.more_vert),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        snap['postText'],
                        style: TextStyle(color: primaryTextColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          //IMAGE SECTION OF THE POST
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            width: double.infinity,
            child: Image.network(snap['postUrl'], fit: BoxFit.cover),
          ),

          //LIKE, COMMENT, SHARE SECTION OF THE POST
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.favorite_border_outlined,
                  color: Colors.red,
                ),
              ),
              //NUMBER OF LIKES CAN GO HERE
              DefaultTextStyle(
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                child: Text('${snap['likes'].length} likes'),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.comment_outlined),
              ),
              //NUMBER OF COMMENTS CAN GO HERE
              DefaultTextStyle(
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                child: const Text('9 comments'),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.send)),
              //NUMBER OF SHARES CAN GO HERE
              DefaultTextStyle(
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                child: const Text('9 shares'),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.bookmark_border),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

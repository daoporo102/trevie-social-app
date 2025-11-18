import 'package:flutter/material.dart';
import 'package:social_media_app/utils/colors.dart';

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? labelColor;
  final String label;
  final VoidCallback onPress;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.iconColor = primaryTextColor,
    required this.label,
    this.labelColor = primaryTextColor,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.bold,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      onPressed: onPress,
    );
  }
}

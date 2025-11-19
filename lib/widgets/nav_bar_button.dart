import 'package:flutter/material.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/widgets/custom_text_button.dart';

class NavBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPress;
  const NavBarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextButton(
      onPressed: onPress,
      backgroundColor: isActive? webBackgroundColor:mobileBackgroundColor,
      overlayColor: isActive? appPrimaryColor:secondaryColor,
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 12,
      ),
      borderRadius: BorderRadius.circular(8),
      minimumSize: const Size(60, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? appPrimaryColor : secondaryColor,
            size: 22,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isActive ? appPrimaryColor : secondaryColor,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

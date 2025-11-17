import 'package:flutter/material.dart';
import 'package:social_media_app/utils/colors.dart';

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
    return TextButton(
      onPressed: onPress,
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        ),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.hovered)) {
            return isActive
                ? webBackgroundColor.withValues(alpha: 0.85)
                : mobileBackgroundColor.withValues(alpha: 0.85);
          }
          return isActive ? webBackgroundColor : mobileBackgroundColor;
        }),
        overlayColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.hovered)) {
            return isActive
                ? appPrimaryColor.withValues(alpha: 0.08)
                : secondaryColor.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.pressed)) {
            return isActive
                ? appPrimaryColor.withValues(alpha: 0.18)
                : secondaryColor.withValues(alpha: 0.18);
          }
          if (states.contains(WidgetState.focused)) {
            return isActive
                ? appPrimaryColor.withValues(alpha: 0.15)
                : secondaryColor.withValues(alpha: 0.15);
          }
          return null;
        }),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        minimumSize: WidgetStateProperty.all(const Size(60, 48)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
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

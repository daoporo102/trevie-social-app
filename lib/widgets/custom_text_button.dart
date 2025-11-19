import 'package:flutter/material.dart';
import 'package:social_media_app/utils/colors.dart';

class CustomTextButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? hoverColor;
  final Color? pressColor;
  final Color? overlayColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Size? minimumSize;
  final double? elevation;

  const CustomTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.hoverColor,
    this.overlayColor,
    this.padding,
    this.borderRadius,
    this.minimumSize,
    this.elevation,
    this.pressColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.pressed)) {
            return pressColor?.withValues(alpha: 0.85) ??
                (backgroundColor ?? textFieldBackgroundColor).withValues(
                  alpha: 0.85,
                );
          }
          if (states.contains(WidgetState.hovered)) {
            return hoverColor?.withValues(alpha: 0.95) ??
                (backgroundColor ?? textFieldBackgroundColor).withValues(
                  alpha: 0.95,
                );
          }
          return backgroundColor ?? textFieldBackgroundColor;
        }),
        overlayColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.pressed)) {
            return overlayColor?.withValues(alpha: 0.18) ??
                (appPrimaryColor).withValues(
                  alpha: 0.18,
                );
          }
          if (states.contains(WidgetState.hovered)) {
            return overlayColor?.withValues(alpha: 0.08) ??
                (appPrimaryColor).withValues(
                  alpha: 0.08,
                );
          }
          if (states.contains(WidgetState.focused)) {
            return overlayColor?.withValues(alpha: 0.15) ??
                (appPrimaryColor).withValues(
                  alpha: 0.15,
                );
          }
          return null;
        }),
        padding: WidgetStateProperty.all(padding??
            const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            )),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
        ),
        minimumSize: WidgetStateProperty.all(minimumSize),
        elevation: WidgetStateProperty.all(elevation??0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: child,
    );
  }
}

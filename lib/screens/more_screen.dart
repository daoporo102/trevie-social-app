import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/auth_methods.dart';
import 'package:social_media_app/screens/login_screen.dart';
import 'package:social_media_app/screens/violations_history_screen.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/custom_snack_bar.dart';
import 'package:social_media_app/widgets/custom_button.dart'; // Add this import

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key, required this.uid});

  final String uid;

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  // Sign out function
  void signOutUser() async {
    try {
      avoidPrint("Starting sign out process...");

      // Get references BEFORE async operations
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final navigator = Navigator.of(context);

      // Sign out from Firebase
      await AuthMethods().signOut();

      // Wait a bit for auth state to propagate
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Clear user provider
      await userProvider.refreshUser();

      if (!mounted) return;

      // Navigate to login
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // Remove all routes
      );

      if (!mounted) return;

      displaySnackBar('Đăng xuất thành công!', context, SnackBarType.success);

      avoidPrint("Sign out complete");
    } catch (e) {
      avoidPrint("Error during sign out: $e");
      if (!mounted) return;
      displaySnackBar('Lỗi đăng xuất: $e', context, SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: width > webScreenSize
          ? null
          : AppBar(
              backgroundColor: mobileBackgroundColor,
              title: const Text(
                'Cài đặt',
                style: TextStyle(color: primaryTextColor),
              ),
              centerTitle: false,
            ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: width > webScreenSize ? width * 0.3 : 16.0,
            vertical: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Violations History Button
              CustomButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ViolationsHistoryScreen(),
                    ),
                  );
                },
                backgroundColor: width > webScreenSize
                    ? webBackgroundColor
                    : mobileBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                hasBorder: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: primaryTextColor),
                    SizedBox(width: 8),
                    Text(
                      'Lịch sử vi phạm',
                      style: TextStyle(
                        fontSize: 18.0,
                        color: primaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sign Out Button
              CustomButton(
                onPressed: signOutUser,
                backgroundColor: width > webScreenSize
                    ? webBackgroundColor
                    : mobileBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                hasBorder: true,
                borderColor: errorBackgroundColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.logout, color: errorBackgroundColor),
                    SizedBox(width: 8),
                    Text(
                      'Đăng xuất',
                      style: TextStyle(
                        fontSize: 18.0,
                        color: errorBackgroundColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/screens/login_screen.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/custom_button.dart';

class AccountBlockedScreen extends StatelessWidget {
  final String reason;
  final DateTime? suspendedAt;

  const AccountBlockedScreen({
    super.key,
    required this.reason,
    this.suspendedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error Icon
                Icon(Icons.block, size: 100, color: Colors.red),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Tài khoản bị khóa',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Reason
                Text(
                  reason,
                  style: TextStyle(fontSize: 16, color: secondaryColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Contact Support
                Text(
                  'Nếu bạn cho rằng đây là lỗi, vui lòng liên hệ quản trị viên qua email: truongquangdao102@gmail.com',
                  style: TextStyle(fontSize: 14, color: secondaryColor),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Back to Login Button
                CustomButton(
                  onPressed: () async {
                    avoidPrint("User clicked 'Back to Login'");

                    // Sign out NOW when user clicks button
                    await FirebaseAuth.instance.signOut();
                    avoidPrint("Signed out from Firebase Auth");

                    if (!context.mounted) return;

                    // Navigate to login - StreamBuilder will handle it
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'Quay lại đăng nhập',
                    style: TextStyle(
                      color: onPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

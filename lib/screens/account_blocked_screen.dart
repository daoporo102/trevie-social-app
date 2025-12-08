import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/screens/login_screen.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/custom_button.dart';

class AccountBlockedScreen extends StatelessWidget {
  final String reason;
  final DateTime? suspendedAt;
  final bool isDeleted;
  final String? deletionReason;
  final String? suspensionReason;


  const AccountBlockedScreen({
    super.key,
    required this.reason,
    this.suspendedAt,
    this.isDeleted = false,
    this.deletionReason,
    this.suspensionReason,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mobileBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Error Icon  - different for deleted vs suspended
                  Icon(
                    isDeleted ? Icons.delete : Icons.block,
                    size: 100,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    isDeleted ? 'Tài khoản đã bị xóa' : 'Tài khoản bị khóa',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Reason (date)
                  Text(
                    reason,
                    style: TextStyle(fontSize: 16, color: secondaryColor),
                    textAlign: TextAlign.center,
                  ),

                  // Deletion Reason (if provided)
                  if (isDeleted &&
                      deletionReason != null &&
                      deletionReason!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lý do xóa:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            deletionReason!,
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryColor,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Suspension Reason (if provided)
                  if (!isDeleted &&
                      suspensionReason != null &&
                      suspensionReason!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lý do tạm khóa:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            suspensionReason!,
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryColor,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                  ],

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
      ),
    );
  }
}

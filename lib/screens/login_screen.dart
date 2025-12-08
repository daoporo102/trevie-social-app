import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/auth_methods.dart';
import 'package:social_media_app/responsive/mobile_screen_layout.dart';
import 'package:social_media_app/responsive/responsive_layout_screen.dart';
import 'package:social_media_app/responsive/web_screen_layout.dart';
import 'package:social_media_app/screens/account_blocked_screen.dart';
import 'package:social_media_app/screens/signup_screen.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/custom_inkwell.dart';
import 'package:social_media_app/widgets/custom_snack_bar.dart';
import 'package:social_media_app/widgets/text_field_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  void loginUser() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    avoidPrint("Starting login process...");
    avoidPrint("Email: ${_emailController.text}");

    // Flag is now managed inside AuthMethods.loginUser()
    String res = await AuthMethods().loginUser(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    avoidPrint("Login result: $res");

    if (!mounted) return;

    // Handle deleted account
    if (res.startsWith("DELETED:")) {
      final timestampStr = res.split(':')[1];
      final timestamp = int.tryParse(timestampStr);
      final deletedAt = timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null;

      setState(() {
        _isLoading = false;
      });

      avoidPrint("Account is deleted, navigating to blocked screen");

      // Navigate to AccountBlockedScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => AccountBlockedScreen(
            reason:
                'Tài khoản đã bị xóa${deletedAt != null ? ' vào ${deletedAt.day}/${deletedAt.month}/${deletedAt.year}' : ''}.',
            suspendedAt: deletedAt, // Reuse this field for deletedAt
            isDeleted: true, // Add new parameter to differentiate
          ),
        ),
        (route) => false,
      );
      return;
    }

    // Handle suspended account
    if (res.startsWith("SUSPENDED:")) {
      final timestampStr = res.split(':')[1];
      final timestamp = int.tryParse(timestampStr);
      final suspendedAt = timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null;

      setState(() {
        _isLoading = false;
      });

      avoidPrint("Account is suspended, navigating to blocked screen");

      // Navigate to AccountBlockedScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => AccountBlockedScreen(
            reason:
                'Tài khoản đã bị tạm khóa${suspendedAt != null ? ' vào ${suspendedAt.day}/${suspendedAt.month}/${suspendedAt.year}' : ''}.',
            suspendedAt: suspendedAt,
          ),
        ),
        (route) => false,
      );
      return;
    }

    if (res == "success") {
      avoidPrint("Login successful");

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.refreshUser();

      if (!mounted) return;

      displaySnackBar('Đăng nhập thành công', context, SnackBarType.success);

      _emailController.clear();
      _passwordController.clear();

      // Pop back to root to let StreamBuilder handle navigation
      // This ensures the StreamBuilder in main.dart detects the auth change
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const ResponsiveLayout(
              webScreenLayout: WebScreenLayout(),
              mobileScreenLayout: MobileScreenLayout(),
            ),
          ),
          (route) => false,
        );
      }
    } else {
      avoidPrint("Login failed: $res");
      displaySnackBar(res, context, SnackBarType.error);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void navigateToSignUpScreen(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SignupScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          padding: MediaQuery.of(context).size.width > webScreenSize
              ? EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width / 3,
                )
              : const EdgeInsets.symmetric(horizontal: 32),
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(flex: 2, child: Container()),
              //svg image
              SvgPicture.asset('assets/images/trevie.svg', height: 64),
              const SizedBox(height: 64),
              //text field input for email
              TextFieldInput(
                textEditingController: _emailController,
                hintText: 'Nhập địa chỉ email của bạn',
                textInputType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                labelText: 'Địa chỉ Email',
              ),
              const SizedBox(height: 24),
              //text field input for password
              TextFieldInput(
                textEditingController: _passwordController,
                hintText: 'Nhập mật khẩu của bạn',
                textInputType: TextInputType.text,
                isPass: true,
                prefixIcon: Icons.lock_outline,
                labelText: 'Mật khẩu',
              ),
              const SizedBox(height: 24),
              //button login
              CustomInkwell(
                title: 'Đăng nhập',
                onTap: loginUser,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 12),
              Flexible(flex: 2, child: Container()),
              //Transitioning to signing up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Text("Don't have an account?"),
                  ),
                  GestureDetector(
                    onTap: () {
                      navigateToSignUpScreen(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: const Text(
                        " Sign up.",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

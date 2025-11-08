import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/auth_methods.dart';
import 'package:social_media_app/responsive/mobile_screen_layout.dart';
import 'package:social_media_app/responsive/responsive_layout_screen.dart';
import 'package:social_media_app/responsive/web_screen_layout.dart';
import 'package:social_media_app/screens/login_screen.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/custom_inkwell.dart';
import 'package:social_media_app/widgets/text_field_input.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  bool _isLoading = false;
  Uint8List? _image;

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
  }

  void signUpUser() async {
    if (_isLoading) return;
    if (_image == null) {
      showSnackBar('Please select a profile image', context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await AuthMethods().signUpUser(
        displayName: _displayNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        file: _image!, // safe after null-check
      );

      if (!mounted) return;
      if (res == "success") {
        //refresh provider so UI updates immediately
        Provider.of<UserProvider>(context, listen: false).refreshUser();
        showSnackBar('Sign up successful!', context);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ResponsiveLayout(
              webScreenLayout: WebScreenLayout(),
              mobileScreenLayout: MobileScreenLayout(),
            ),
          ),
        );
      } else {
        showSnackBar(res, context);
      }
    } catch (e) {
      if (!mounted) return;
      showSnackBar(e.toString(), context);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void navigateToLoginScreen(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  Future<void> selectImage() async {
    try {
      final Uint8List? im = await pickImage(ImageSource.gallery);
      if (!mounted) return;
      if (im == null) {
        showSnackBar('No image selected', context);
        return;
      }
      setState(() {
        _image = im;
      });
    } catch (e) {
      if (!mounted) return;
      showSnackBar('Failed to pick image: $e', context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewInsets = MediaQuery.of(context).viewInsets;
            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: viewInsets.bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(flex: 2, child: Container()),
                        //svg image
                        SvgPicture.asset(
                          'assets/images/trevie.svg',
                          height: 64,
                        ),
                        const SizedBox(height: 64),
                        //
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 64,
                              backgroundImage: _image != null
                                  ? MemoryImage(_image!)
                                  : null,
                              backgroundColor: secondaryColor,
                            ),
                            Positioned(
                              bottom: -10,
                              left: 80,
                              child: IconButton(
                                onPressed: _isLoading ? null : selectImage,
                                icon: const Icon(Icons.add_a_photo),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        //text field input for displayName
                        TextFieldInput(
                          textEditingController: _displayNameController,
                          hintText: 'Enter your display name',
                          textInputType: TextInputType.text,
                        ),
                        const SizedBox(height: 24),
                        //text field input for email
                        TextFieldInput(
                          textEditingController: _emailController,
                          hintText: 'Enter your email',
                          textInputType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 24),
                        //text field input for password
                        TextFieldInput(
                          textEditingController: _passwordController,
                          hintText: 'Enter your password',
                          textInputType: TextInputType.text,
                          isPass: true,
                        ),
                        const SizedBox(height: 24),
                        //button login
                        CustomInkwell(
                          title: 'Đăng ký',
                          onTap: signUpUser,
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
                              child: const Text("Already have an account?"),
                            ),
                            GestureDetector(
                              onTap: () {
                                // Handle sign up navigation
                                navigateToLoginScreen(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: const Text(
                                  " Log in.",
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
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:social_media_app/resources/auth_methods.dart';
import 'package:social_media_app/responsive/mobile_screen_layout.dart';
import 'package:social_media_app/responsive/responsive_layout_screen.dart';
import 'package:social_media_app/responsive/web_screen_layout.dart';
import 'package:social_media_app/screens/account_blocked_screen.dart';
import 'package:social_media_app/screens/login_screen.dart';
import 'package:social_media_app/utils/colors.dart';
import 'package:social_media_app/utils/global_variables.dart';
import 'package:social_media_app/utils/utils.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Guard against duplicate initialization
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await FirebaseAppCheck.instance.activate(
    providerWeb: ReCaptchaV3Provider(
      '6Lf1_ggsAAAAAIWDcI-DLcClxfDs_F9DH2BDcJVb',
    ),
    providerAndroid:
        AndroidDebugProvider(), // switch to PlayIntegrity for release
    // appleProvider: AppleProvider.debug, // switch to DeviceCheck for release
  );

  // Initialize Vietnamese date formatting
  await initializeDateFormatting('vi', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  // Allow tests to inject a fake auth stream to avoid Firebase calls
  final Stream<User?>? authStream;
  const MyApp({super.key, this.authStream});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light().copyWith(
          scaffoldBackgroundColor: mobileBackgroundColor,
          appBarTheme: AppBarTheme(
            surfaceTintColor: mobileBackgroundColor.withValues(alpha: 0.95),
            // Enable scroll effects on AppBar
            scrolledUnderElevation: 4.0,
          ),
          iconButtonTheme: IconButtonThemeData(
            style: ButtonStyle(
              overlayColor: WidgetStateProperty.resolveWith<Color?>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.pressed)) {
                  return appPrimaryColor.withValues(alpha: 0.18);
                }
                if (states.contains(WidgetState.hovered)) {
                  return appPrimaryColor.withValues(alpha: 0.08);
                }
                if (states.contains(WidgetState.focused)) {
                  return appPrimaryColor.withValues(alpha: 0.15);
                }
                return null;
              }),
              backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.pressed)) {
                  return textFieldBackgroundColor.withValues(alpha: 0.85);
                }
                if (states.contains(WidgetState.hovered)) {
                  return textFieldBackgroundColor.withValues(alpha: 0.95);
                }
                return null;
              }),
            ),
          ),
        ),
        title: 'TreVie',
        home: StreamBuilder(
          // Use injected stream in tests, real FirebaseAuth stream in app
          stream: authStream ?? FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            avoidPrint("StreamBuilder state: ${snapshot.connectionState}");
            avoidPrint("Has data: ${snapshot.hasData}");
            avoidPrint("User UID: ${snapshot.data?.uid}");

            if (snapshot.connectionState == ConnectionState.active) {
              if (snapshot.hasData) {
                // User is logged in, always check account status
                avoidPrint("User authenticated, checking account status...");

                return FutureBuilder<Map<String, dynamic>>(
                  key: ValueKey(snapshot.data!.uid), // Add this line
                  future:
                      Future.delayed(
                        const Duration(milliseconds: 100), // Small delay
                        () => AuthMethods().checkUserAccountStatus(),
                      ).timeout(
                        const Duration(seconds: 10),
                        onTimeout: () {
                          avoidPrint("Status check timed out");
                          return {
                            'isValid': false,
                            'reason': 'Timeout kiểm tra tài khoản',
                          };
                        },
                      ),
                  builder: (context, statusSnapshot) {
                    if (statusSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      avoidPrint("Waiting for account status check...");
                      return customCircularProgressIndicator();
                    }

                    if (statusSnapshot.hasError) {
                      avoidPrint(
                        "Error in statusSnapshot: ${statusSnapshot.error}",
                      );
                      avoidPrint("Stack trace: ${statusSnapshot.stackTrace}");

                      // Instead of showing error screen, sign out and return to login
                      FirebaseAuth.instance.signOut();
                      return const LoginScreen();
                    }

                    final status = statusSnapshot.data ?? {'isValid': false};

                    avoidPrint("Status check result: $status");

                    if (status['isValid'] == true) {
                      avoidPrint("Showing main app");
                      // Account is valid, show app
                      return ResponsiveLayout(
                        webScreenLayout: WebScreenLayout(),
                        mobileScreenLayout: MobileScreenLayout(),
                      );
                    } else {
                      avoidPrint("Showing blocked screen: ${status['reason']}");
                      // Account is suspended or deleted
                      return AccountBlockedScreen(
                        reason: status['reason'] ?? 'Tài khoản bị khóa',
                        suspendedAt: status['suspendedAt'],
                      );
                    }
                  },
                );
              } else if (snapshot.hasError) {
                avoidPrint("StreamBuilder error: ${snapshot.error}");
                return Center(child: Text('${snapshot.error}'));
              }
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              avoidPrint("Waiting for auth state...");
              return customCircularProgressIndicator();
            }

            // No user authenticated - show login
            avoidPrint("No user, showing login screen");
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

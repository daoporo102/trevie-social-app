// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;

// correct helper import for your versions
import 'package:firebase_core_platform_interface/test.dart';

import 'package:social_media_app/main.dart';
import 'package:social_media_app/screens/login_screen.dart';
// import 'package:social_media_app/firebase_options.dart'; // keep if main.dart uses it
import 'package:social_media_app/responsive/mobile_screen_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Set up method-channel mocks so your app’s own init can run.
    setupFirebaseCoreMocks();

    // 🚫 Do NOT call Firebase.initializeApp() here.
  });

  // 🚫 Remove tearDownAll that deletes the app.

  testWidgets('MyApp shows LoginScreen when not authenticated', (tester) async {
    await tester.pumpWidget(MyApp(authStream: Stream<User?>.value(null)));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('LoginScreen renders standalone', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MobileScreenLayout renders and shows a CupertinoTabBar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MobileScreenLayout()));
    expect(find.byType(MobileScreenLayout), findsOneWidget);
    expect(find.byType(CupertinoTabBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
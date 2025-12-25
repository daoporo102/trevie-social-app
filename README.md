TreVie social app is a Flutter project for Vietnamese people

Hosting URL: https://social-media-app-8910d.web.app

How to build Firebase Hosting with update code:

1.Project rebuild

  flutter build web --release

2.Deploy to Firebase Hosting

  firebase deploy --only hosting

how to rebuild file APK after updated code

1. delete cache

  flutter clean

  flutter pub get

2. Create file APK Release version

  flutter build apk --release

3. Get file APK at directory

  build\app\outputs\flutter-apk\app-release.apk
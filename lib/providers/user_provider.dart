import 'package:flutter/widgets.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/resources/auth_methods.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  final AuthMethods _authMethod = AuthMethods();

  // Getter that can return null if user is not loaded
  User? get getUserrOrNull => _user;

  Future<void> refreshUser() async {
    User user = await _authMethod.getUserDetails();
    _user = user;
    notifyListeners();
  }

}

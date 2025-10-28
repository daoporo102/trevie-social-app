import 'package:flutter/widgets.dart';
import 'package:social_media_app/models/user.dart' as model;
import 'package:social_media_app/resources/auth_method.dart';

class UserProvider with ChangeNotifier {
  model.User? _user;
  final AuthMethod _authMethod = AuthMethod();

  model.User get getUser => _user!;

  Future<void> refreshUser() async {
    model.User user = await _authMethod.getUserDetails();
    _user = user;
    notifyListeners();
    
  }
}

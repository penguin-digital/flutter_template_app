import 'package:flutter/material.dart';
import 'package:flutter_template_app/application/services/auth_service.dart';
import 'package:flutter_template_app/core/dependency_injection/locator.dart';
import 'package:flutter_template_app/core/error/error_handling.dart';
import 'package:flutter_template_app/core/mixins/validation_mixin.dart';
import 'package:stacked_services/stacked_services.dart';

enum SocialSignIn {
  GoogleSignIn,
  AppleSignIn,
}

enum SignIn {
  Login,
  Signup,
}

class LandingViewController extends ChangeNotifier with Validation {
  final NavigationService _navigationService;
  final SnackbarService _snackbarService;
  final AuthService _authService;

  LandingViewController({
    NavigationService? navigationService,
    SnackbarService? snackbarService,
    AuthService? authService,
  })  : _navigationService = navigationService ?? locator<NavigationService>(),
        _snackbarService = snackbarService ?? locator<SnackbarService>(),
        _authService = authService ?? locator<AuthService>();

  //Flags
  bool? isLoading;

  String _email = '';
  String _emailValidationMessage = '';
  String _password = '';
  String _passwordValidationMessage = '';
  String _confirmPassword = '';
  String _confirmPasswordValidationMessage = '';

  String get email => _email;
  String get emailValidationMessage => _emailValidationMessage;
  String get password => _password;
  String get passwordValidationMessage => _passwordValidationMessage;
  String get confirmPassword => _confirmPassword;
  String get confirmPasswordValidationMessage =>
      _confirmPasswordValidationMessage;

  Future<void> submitLoginForm({required SignIn signInType}) async {
    _emailValidationMessage = validateEmail(_email);
    _passwordValidationMessage = validatePassword(_password);
    _confirmPasswordValidationMessage =
        validateConfirmPassword(_password, _confirmPassword);

    if (_emailValidationMessage.isNotEmpty ||
        _passwordValidationMessage.isNotEmpty) {
      notifyListeners();
      return;
    }
    if (signInType == SignIn.Signup &&
        _confirmPasswordValidationMessage.isNotEmpty) {
      notifyListeners();
      return;
    }

    isLoading = true;
    try {
      final userExists = await _authService.signInWithEmailAndPassword(
          signInType: signInType, email: email, password: password);
      if (!userExists) {
        _navigationService.clearStackAndShow('home-view');
      } else {
        _navigationService.clearStackAndShow('login-view');
      }
    } on CustomError catch (e) {
      isLoading = false;
      _snackbarService.showSnackbar(message: e.message);
    }
  }
}

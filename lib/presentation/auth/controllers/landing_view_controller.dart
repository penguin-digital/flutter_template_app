import 'package:flutter/material.dart';
import 'package:flutter_template_app/application/services/auth_service.dart';
import 'package:flutter_template_app/core/dependency_injection/locator.dart';
import 'package:flutter_template_app/core/error/error_handling.dart';
import 'package:flutter_template_app/core/mixins/validation_mixin.dart';
import 'package:flutter_template_app/core/router/router.dart' as Router;
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
    required NavigationService navigationService,
    required SnackbarService snackbarService,
    required AuthService authService,
  })  : _navigationService = navigationService,
        _snackbarService = snackbarService,
        _authService = authService;

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
        _navigationService.clearStackAndShow(Router.Router.landingView);
      } else {
        _navigationService.clearStackAndShow(Router.Router.homeView);
      }
    } on CustomError catch (e) {
      isLoading = false;
      _snackbarService.showSnackbar(message: e.message);
    }
  }

  // TODO: IMPLEMENT REAL THING
  void updateEmail(String email) {
    _email = email;
    notifyListeners();
  }

  // TODO: IMPLEMENT REAL THING
  void updatePassword(String password) {
    _password = password;
    notifyListeners();
  }

  // TODO: IMPLEMENT REAL THING
  void updateConfirmPassword(String confirmPassword) {
    _confirmPassword = confirmPassword;
    notifyListeners();
  }

  // TODO: IMPLEMENT REAL THING
  void navigateToForgotPassword() {
    _navigationService.navigateTo('forgot-password-view');
  }
}

final landingViewControllerProvider =
    ChangeNotifierProvider<LandingViewController>(
  (ref) {
    return LandingViewController(
      navigationService: locator<NavigationService>(),
      snackbarService: locator<SnackbarService>(),
      authService: locator<AuthService>(),
    );
  },
);

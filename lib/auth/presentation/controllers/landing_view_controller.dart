import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_template_app/application/services/shared_preferences_service.dart';
import 'package:flutter_template_app/auth/domain/use_cases/sign_in_with_email_and_pass.dart';
import 'package:flutter_template_app/auth/domain/use_cases/sign_in_with_oauth.dart';
import 'package:flutter_template_app/core/dependency_injection/locator.dart';
import 'package:flutter_template_app/core/error/error_handling.dart';
import 'package:flutter_template_app/core/mixins/validation_mixin.dart';
import 'package:flutter_template_app/core/router/router.dart' as Router;
import 'package:flutter_template_app/user/domain/repositories/user_repository.dart';
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
  // final AuthService _authService;
  final UserRepository _userRepository;
  final SharedPreferenceApi _sharedPreferenceApi;
  final SignInWithEmailAndPasswordUseCase _signInWithEmailAndPasswordUseCase;
  final SignInWithOAuthUseCase _signInWithOAuthUseCase;

  LandingViewController({
    required NavigationService navigationService,
    required SnackbarService snackbarService,
    // required AuthService authService,
    required UserRepository userRepository,
    required SharedPreferenceApi sharedPreferenceApi,
    required SignInWithEmailAndPasswordUseCase
        signInWithEmailAndPasswordUseCase,
    required SignInWithOAuthUseCase signInWithOAuthUseCase,
  })  : _navigationService = navigationService,
        _snackbarService = snackbarService,
        // _authService = authService,
        _userRepository = userRepository,
        _sharedPreferenceApi = sharedPreferenceApi,
        _signInWithEmailAndPasswordUseCase = signInWithEmailAndPasswordUseCase,
        _signInWithOAuthUseCase = signInWithOAuthUseCase;

  //Flags
  bool isLoading = false;

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
      final userExists = await _signInWithEmailAndPasswordUseCase.call(
          signInType: signInType, email: email, password: password);

      if (!userExists) {
        _navigationService.clearStackAndShow(Router.Router.onboardingView);
      } else {
        _navigationService.clearStackAndShow(Router.Router.homeView);
      }
    } on CustomError catch (e) {
      isLoading = false;
      _snackbarService.showSnackbar(message: e.message);
    }
  }

  void updateEmail(String email) {
    _email = email;
    notifyListeners();
  }

  void updatePassword(String password) {
    _password = password;
    notifyListeners();
  }

  void updateConfirmPassword(String confirmPassword) {
    _confirmPassword = confirmPassword;
    notifyListeners();
  }

  Future<void> signinWithOAuth(SocialSignIn signInType) async {
    // TODO: FIND A BETTER WAY TO INITIALIZE THIS
    await _sharedPreferenceApi.init();
    isLoading = true;
    try {
      final userHasRegisteredBefore =
          await _signInWithOAuthUseCase.call(signInType: signInType);
      log("user registrado => $userHasRegisteredBefore");
      if (!userHasRegisteredBefore) {
        await _sharedPreferenceApi.setShowHomeOnboarding(val: true);
        // await _sharedPreferenceApi.setShowSearchOnboarding(val: true);
        _navigationService.clearStackAndShow(Router.Router.onboardingView);
      } else {
        _navigationService.clearStackAndShow(Router.Router.homeView,
            arguments: {'currentUser': _userRepository.currentUser});
      }
    } on CustomError catch (e) {
      isLoading = false;
      _snackbarService.showSnackbar(message: e.message);
    }
  }

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
      // authService: locator<AuthService>(),
      userRepository: locator<UserRepository>(),
      sharedPreferenceApi: locator<SharedPreferenceApi>(),
      signInWithEmailAndPasswordUseCase:
          locator<SignInWithEmailAndPasswordUseCase>(),
      signInWithOAuthUseCase: locator<SignInWithOAuthUseCase>(),
    );
  },
);
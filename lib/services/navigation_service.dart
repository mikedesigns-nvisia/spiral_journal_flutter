import 'package:flutter/material.dart';

/// Navigation service for managing app-wide navigation and routing
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  static NavigationService get instance => _instance;

  // Global key for the main screen state
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Callback to switch tabs in the main screen
  Function(int)? _onTabChanged;

  void setTabChangeCallback(Function(int) callback) {
    _onTabChanged = callback;
  }

  void switchToTab(int tabIndex) {
    _onTabChanged?.call(tabIndex);
  }

  // Tab indices for easy reference
  static const int journalTab = 0;
  static const int historyTab = 1;
  static const int mirrorTab = 2;
  static const int insightsTab = 3;
  static const int settingsTab = 4;

  /// Navigate to main app (after onboarding completion)
  Future<void> navigateToMainApp() async {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/main',
        (route) => false,
      );
    }
  }

  /// Navigate to onboarding screen
  Future<void> navigateToOnboarding() async {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/onboarding',
        (route) => false,
      );
    }
  }

  /// Navigate to profile setup screen
  Future<void> navigateToProfileSetup() async {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/profile-setup',
        (route) => false,
      );
    }
  }

  // PIN setup navigation removed - using biometrics-only authentication

  /// Navigate back
  void goBack() {
    final context = navigatorKey.currentContext;
    if (context != null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Push a new route
  Future<T?> pushNamed<T extends Object?>(String routeName, {Object? arguments}) async {
    final context = navigatorKey.currentContext;
    if (context != null) {
      return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
    }
    return null;
  }

  /// Replace current route
  Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) async {
    final context = navigatorKey.currentContext;
    if (context != null) {
      return Navigator.of(context).pushReplacementNamed<T, TO>(
        routeName,
        arguments: arguments,
        result: result,
      );
    }
    return null;
  }

  /// Push and remove all previous routes
  Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String newRouteName,
    bool Function(Route<dynamic>) predicate, {
    Object? arguments,
  }) async {
    final context = navigatorKey.currentContext;
    if (context != null) {
      return Navigator.of(context).pushNamedAndRemoveUntil<T>(
        newRouteName,
        predicate,
        arguments: arguments,
      );
    }
    return null;
  }

  /// Get current route name
  String? get currentRouteName {
    final context = navigatorKey.currentContext;
    if (context != null) {
      return ModalRoute.of(context)?.settings.name;
    }
    return null;
  }

  /// Check if can go back
  bool get canGoBack {
    final context = navigatorKey.currentContext;
    return context != null && Navigator.of(context).canPop();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Navigation states for the fresh install flow
enum NavigationState {
  splash,
  onboarding,
  profileSetup,
  journal,
  completed
}

/// Flow state containing current navigation state and rules
class FlowState {
  final NavigationState currentState;
  final bool canGoBack;
  final String? nextRoute;
  final bool isFlowComplete;
  
  const FlowState({
    required this.currentState,
    this.canGoBack = false,
    this.nextRoute,
    this.isFlowComplete = false,
  });

  FlowState copyWith({
    NavigationState? currentState,
    bool? canGoBack,
    String? nextRoute,
    bool? isFlowComplete,
  }) {
    return FlowState(
      currentState: currentState ?? this.currentState,
      canGoBack: canGoBack ?? this.canGoBack,
      nextRoute: nextRoute ?? this.nextRoute,
      isFlowComplete: isFlowComplete ?? this.isFlowComplete,
    );
  }

  @override
  String toString() {
    return 'FlowState(currentState: $currentState, canGoBack: $canGoBack, nextRoute: $nextRoute, isFlowComplete: $isFlowComplete)';
  }
}

/// Controller for managing mandatory navigation sequence during fresh install
class NavigationFlowController extends ChangeNotifier {
  static NavigationFlowController? _instance;
  
  /// Singleton instance
  static NavigationFlowController get instance {
    _instance ??= NavigationFlowController._internal();
    return _instance!;
  }
  
  NavigationFlowController._internal();

  FlowState _currentFlowState = const FlowState(
    currentState: NavigationState.splash,
    canGoBack: false,
    nextRoute: '/onboarding',
  );

  bool _isFlowActive = false;
  bool _isNavigating = false;

  /// Current flow state
  FlowState get currentFlowState => _currentFlowState;

  /// Whether the fresh install flow is currently active
  bool get isFlowActive => _isFlowActive;

  /// Whether navigation is currently in progress
  bool get isNavigating => _isNavigating;

  /// Route mapping for navigation states
  static const Map<NavigationState, String> _stateRoutes = {
    NavigationState.splash: '/',
    NavigationState.onboarding: '/onboarding',
    NavigationState.profileSetup: '/profile-setup',
    NavigationState.journal: '/main',
  };

  /// Reverse route mapping for determining state from route
  static const Map<String, NavigationState> _routeStates = {
    '/': NavigationState.splash,
    '/onboarding': NavigationState.onboarding,
    '/profile-setup': NavigationState.profileSetup,
    '/main': NavigationState.journal,
  };

  /// Navigation sequence definition
  static const List<NavigationState> _navigationSequence = [
    NavigationState.splash,
    NavigationState.onboarding,
    NavigationState.profileSetup,
    NavigationState.journal,
    NavigationState.completed,
  ];

  /// Start the fresh install flow
  Future<void> startFreshFlow(BuildContext context) async {
    debugPrint('NavigationFlowController: Starting fresh install flow');
    
    _isFlowActive = true;
    _updateFlowState(const FlowState(
      currentState: NavigationState.splash,
      canGoBack: false,
      nextRoute: '/onboarding',
    ));

    // Set up system back button handling
    _setupBackButtonHandling();
    
    notifyListeners();
  }

  /// Stop the fresh install flow
  void stopFreshFlow() {
    debugPrint('NavigationFlowController: Stopping fresh install flow');
    
    _isFlowActive = false;
    _updateFlowState(_currentFlowState.copyWith(isFlowComplete: true));
    
    notifyListeners();
  }

  /// Update the current flow state
  void _updateFlowState(FlowState newState) {
    debugPrint('NavigationFlowController: Updating flow state from ${_currentFlowState.currentState} to ${newState.currentState}');
    _currentFlowState = newState;
  }

  /// Advance to the next state in the sequence
  Future<bool> advanceToNextState(BuildContext context) async {
    if (!_isFlowActive || _isNavigating) {
      debugPrint('NavigationFlowController: Cannot advance - flow inactive or already navigating');
      return false;
    }

    final currentIndex = _navigationSequence.indexOf(_currentFlowState.currentState);
    if (currentIndex == -1 || currentIndex >= _navigationSequence.length - 1) {
      debugPrint('NavigationFlowController: Cannot advance - at end of sequence');
      return false;
    }

    final nextState = _navigationSequence[currentIndex + 1];
    return await _navigateToState(context, nextState);
  }

  /// Navigate to a specific state
  Future<bool> _navigateToState(BuildContext context, NavigationState targetState) async {
    if (_isNavigating) {
      debugPrint('NavigationFlowController: Navigation already in progress');
      return false;
    }

    _isNavigating = true;
    
    try {
      final targetRoute = _stateRoutes[targetState];
      if (targetRoute == null) {
        debugPrint('NavigationFlowController: No route found for state $targetState');
        return false;
      }

      debugPrint('NavigationFlowController: Navigating to $targetState ($targetRoute)');

      // Update flow state before navigation
      final nextIndex = _navigationSequence.indexOf(targetState) + 1;
      final nextState = nextIndex < _navigationSequence.length 
          ? _navigationSequence[nextIndex] 
          : NavigationState.completed;
      
      final nextRoute = nextState != NavigationState.completed 
          ? _stateRoutes[nextState] 
          : null;

      _updateFlowState(FlowState(
        currentState: targetState,
        canGoBack: _canNavigateBack(targetState),
        nextRoute: nextRoute,
        isFlowComplete: targetState == NavigationState.journal,
      ));

      // Perform navigation
      if (targetState == NavigationState.journal) {
        // Final destination - complete the flow
        await Navigator.of(context).pushNamedAndRemoveUntil(
          targetRoute,
          (route) => false,
        );
        stopFreshFlow();
      } else {
        // Intermediate step - replace current route
        await Navigator.of(context).pushReplacementNamed(targetRoute);
      }

      notifyListeners();
      return true;

    } catch (e) {
      debugPrint('NavigationFlowController: Navigation error: $e');
      return false;
    } finally {
      _isNavigating = false;
    }
  }

  /// Check if back navigation is allowed for a given state
  bool _canNavigateBack(NavigationState state) {
    // During fresh install flow, back navigation is generally not allowed
    // to maintain the mandatory sequence
    if (_isFlowActive) {
      return false;
    }
    
    // Allow back navigation only after flow is complete
    return state == NavigationState.journal || state == NavigationState.completed;
  }

  /// Check if back navigation is currently allowed
  bool canNavigateBack(String? currentRoute) {
    if (!_isFlowActive) {
      return true; // Normal navigation rules apply when flow is not active
    }

    final currentState = _routeStates[currentRoute];
    if (currentState == null) {
      return true; // Unknown route, allow normal navigation
    }

    return _canNavigateBack(currentState);
  }

  /// Get the next route for the current state
  String? getNextRoute(String currentRoute) {
    final currentState = _routeStates[currentRoute];
    if (currentState == null) {
      return null;
    }

    final currentIndex = _navigationSequence.indexOf(currentState);
    if (currentIndex == -1 || currentIndex >= _navigationSequence.length - 1) {
      return null;
    }

    final nextState = _navigationSequence[currentIndex + 1];
    return _stateRoutes[nextState];
  }

  /// Enforce the flow sequence by preventing unauthorized navigation
  bool enforceFlowSequence(String? targetRoute) {
    if (!_isFlowActive) {
      return true; // Allow all navigation when flow is not active
    }

    final targetState = _routeStates[targetRoute];
    if (targetState == null) {
      return false; // Unknown route not allowed during flow
    }

    final currentIndex = _navigationSequence.indexOf(_currentFlowState.currentState);
    final targetIndex = _navigationSequence.indexOf(targetState);

    // Only allow navigation to the next state in sequence or current state
    return targetIndex <= currentIndex + 1;
  }

  /// Set up system back button handling
  void _setupBackButtonHandling() {
    // This will be handled by individual screens using WillPopScope
    // The controller provides the canNavigateBack method for screens to use
  }

  /// Handle system back button press
  Future<bool> handleBackButton(String? currentRoute) async {
    if (!_isFlowActive) {
      return true; // Allow normal back navigation
    }

    final canGoBack = canNavigateBack(currentRoute);
    
    if (!canGoBack) {
      // Provide haptic feedback to indicate blocked navigation
      HapticFeedback.lightImpact();
      debugPrint('NavigationFlowController: Back navigation blocked during fresh install flow');
    }

    return canGoBack;
  }

  /// Update flow state based on current route (for external navigation)
  void updateStateFromRoute(String route) {
    final state = _routeStates[route];
    if (state != null && state != _currentFlowState.currentState) {
      debugPrint('NavigationFlowController: Updating state from route: $route -> $state');
      
      final nextIndex = _navigationSequence.indexOf(state) + 1;
      final nextState = nextIndex < _navigationSequence.length 
          ? _navigationSequence[nextIndex] 
          : NavigationState.completed;
      
      final nextRoute = nextState != NavigationState.completed 
          ? _stateRoutes[nextState] 
          : null;

      _updateFlowState(FlowState(
        currentState: state,
        canGoBack: _canNavigateBack(state),
        nextRoute: nextRoute,
        isFlowComplete: state == NavigationState.journal,
      ));

      if (state == NavigationState.journal) {
        stopFreshFlow();
      }

      notifyListeners();
    }
  }

  /// Reset the flow controller
  void reset() {
    debugPrint('NavigationFlowController: Resetting flow controller');
    
    _isFlowActive = false;
    _isNavigating = false;
    _currentFlowState = const FlowState(
      currentState: NavigationState.splash,
      canGoBack: false,
      nextRoute: '/onboarding',
    );
    
    notifyListeners();
  }

  @override
  void dispose() {
    _instance = null;
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/services/navigation_flow_controller.dart';

void main() {
  group('NavigationFlowController', () {
    late NavigationFlowController controller;

    setUp(() {
      controller = NavigationFlowController.instance;
      controller.reset(); // Ensure clean state for each test
    });

    tearDown(() {
      controller.reset();
    });

    group('Initialization', () {
      test('should have correct initial state', () {
        expect(controller.currentFlowState.currentState, NavigationState.splash);
        expect(controller.currentFlowState.canGoBack, false);
        expect(controller.currentFlowState.nextRoute, '/onboarding');
        expect(controller.currentFlowState.isFlowComplete, false);
        expect(controller.isFlowActive, false);
        expect(controller.isNavigating, false);
      });

      test('should be singleton', () {
        final controller1 = NavigationFlowController.instance;
        final controller2 = NavigationFlowController.instance;
        expect(identical(controller1, controller2), true);
      });
    });

    group('Flow State Management', () {
      testWidgets('should start fresh flow correctly', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(home: Container()));
        final context = tester.element(find.byType(Container));
        
        await controller.startFreshFlow(context);
        
        expect(controller.isFlowActive, true);
        expect(controller.currentFlowState.currentState, NavigationState.splash);
        expect(controller.currentFlowState.canGoBack, false);
        expect(controller.currentFlowState.nextRoute, '/onboarding');
      });

      test('should stop fresh flow correctly', () {
        controller.stopFreshFlow();
        
        expect(controller.isFlowActive, false);
        expect(controller.currentFlowState.isFlowComplete, true);
      });

      test('should reset to initial state', () {
        // Modify state first
        controller.stopFreshFlow();
        expect(controller.isFlowActive, false);
        
        // Reset and verify
        controller.reset();
        expect(controller.isFlowActive, false);
        expect(controller.isNavigating, false);
        expect(controller.currentFlowState.currentState, NavigationState.splash);
        expect(controller.currentFlowState.canGoBack, false);
      });
    });

    group('Navigation Sequence Logic', () {
      test('should return correct next route for each state', () {
        expect(controller.getNextRoute('/'), '/onboarding');
        expect(controller.getNextRoute('/onboarding'), '/profile-setup');
        expect(controller.getNextRoute('/profile-setup'), '/main');
        expect(controller.getNextRoute('/main'), null);
      });

      test('should enforce flow sequence correctly', () {
        // Without active flow, all navigation should be allowed
        expect(controller.enforceFlowSequence('/main'), true);
        expect(controller.enforceFlowSequence('/profile-setup'), true);
        expect(controller.enforceFlowSequence('/unknown'), true); // Unknown routes allowed when flow not active
      });

      test('should update state from route correctly', () {
        controller.updateStateFromRoute('/onboarding');
        expect(controller.currentFlowState.currentState, NavigationState.onboarding);
        
        controller.updateStateFromRoute('/profile-setup');
        expect(controller.currentFlowState.currentState, NavigationState.profileSetup);
        
        controller.updateStateFromRoute('/main');
        expect(controller.currentFlowState.currentState, NavigationState.journal);
        expect(controller.currentFlowState.isFlowComplete, true);
      });
    });

    group('Back Navigation Control', () {
      test('should allow back navigation when flow is not active', () {
        expect(controller.canNavigateBack('/main'), true);
        expect(controller.canNavigateBack('/profile-setup'), true);
        expect(controller.canNavigateBack('/onboarding'), true);
      });

      test('should handle back button correctly', () async {
        // Without active flow
        expect(await controller.handleBackButton('/main'), true);
      });

      test('should allow back navigation for unknown routes', () {
        expect(controller.canNavigateBack('/unknown-route'), true);
      });
    });

    group('FlowState', () {
      test('should create FlowState correctly', () {
        const state = FlowState(
          currentState: NavigationState.onboarding,
          canGoBack: true,
          nextRoute: '/profile-setup',
          isFlowComplete: false,
        );
        
        expect(state.currentState, NavigationState.onboarding);
        expect(state.canGoBack, true);
        expect(state.nextRoute, '/profile-setup');
        expect(state.isFlowComplete, false);
      });

      test('should copy FlowState with changes', () {
        const originalState = FlowState(
          currentState: NavigationState.splash,
          canGoBack: false,
          nextRoute: '/onboarding',
          isFlowComplete: false,
        );
        
        final newState = originalState.copyWith(
          currentState: NavigationState.onboarding,
          canGoBack: true,
        );
        
        expect(newState.currentState, NavigationState.onboarding);
        expect(newState.canGoBack, true);
        expect(newState.nextRoute, '/onboarding'); // Unchanged
        expect(newState.isFlowComplete, false); // Unchanged
      });

      test('should have proper toString implementation', () {
        const state = FlowState(
          currentState: NavigationState.onboarding,
          canGoBack: true,
          nextRoute: '/profile-setup',
          isFlowComplete: false,
        );
        
        final string = state.toString();
        expect(string, contains('NavigationState.onboarding'));
        expect(string, contains('canGoBack: true'));
        expect(string, contains('nextRoute: /profile-setup'));
        expect(string, contains('isFlowComplete: false'));
      });
    });

    group('Navigation States', () {
      test('should have all required navigation states', () {
        expect(NavigationState.values, contains(NavigationState.splash));
        expect(NavigationState.values, contains(NavigationState.onboarding));
        expect(NavigationState.values, contains(NavigationState.profileSetup));
        expect(NavigationState.values, contains(NavigationState.journal));
        expect(NavigationState.values, contains(NavigationState.completed));
      });
    });

    group('Edge Cases', () {
      test('should handle stop flow when not active', () {
        expect(controller.isFlowActive, false);
        
        controller.stopFreshFlow();
        expect(controller.isFlowActive, false);
        expect(controller.currentFlowState.isFlowComplete, true);
      });

      test('should handle navigation to unknown routes', () {
        expect(controller.getNextRoute('/unknown'), null);
        expect(controller.enforceFlowSequence('/unknown'), true); // Allowed when flow not active
      });

      test('should handle state updates for unknown routes', () {
        final initialState = controller.currentFlowState.currentState;
        
        controller.updateStateFromRoute('/unknown');
        expect(controller.currentFlowState.currentState, initialState); // Should not change
      });
    });

    group('ChangeNotifier Behavior', () {
      test('should notify listeners when flow stops', () {
        bool notified = false;
        controller.addListener(() {
          notified = true;
        });
        
        controller.stopFreshFlow();
        expect(notified, true);
      });

      test('should notify listeners when state updates', () {
        bool notified = false;
        controller.addListener(() {
          notified = true;
        });
        
        controller.updateStateFromRoute('/onboarding');
        expect(notified, true);
      });
    });
  });
}
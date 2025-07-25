import 'dart:async';
import 'package:flutter/material.dart';
import '../models/core.dart';
import '../models/journal_entry.dart';
import '../screens/core_library_screen.dart';

/// Service for managing contextual navigation between core displays
/// Handles context creation, preservation, and restoration for seamless navigation
class CoreNavigationContextService {
  static final CoreNavigationContextService _instance = CoreNavigationContextService._internal();
  factory CoreNavigationContextService() => _instance;
  CoreNavigationContextService._internal();

  // Navigation context stack for state preservation
  final List<CoreNavigationContext> _contextStack = [];
  
  // Current navigation context
  CoreNavigationContext? _currentContext;
  
  // Stream controller for navigation events
  final StreamController<CoreNavigationContext> _navigationController = 
      StreamController<CoreNavigationContext>.broadcast();

  /// Stream of navigation context changes
  Stream<CoreNavigationContext> get navigationStream => _navigationController.stream;

  /// Current navigation context
  CoreNavigationContext? get currentContext => _currentContext;

  /// Navigation history stack
  List<CoreNavigationContext> get contextHistory => List.unmodifiable(_contextStack);

  /// Creates a new navigation context with source tracking and metadata
  CoreNavigationContext createContext({
    required String sourceScreen,
    String? triggeredBy,
    String? targetCoreId,
    JournalEntry? relatedEntry,
    Map<String, dynamic>? additionalData,
  }) {
    final context = CoreNavigationContext(
      sourceScreen: sourceScreen,
      triggeredBy: triggeredBy,
      targetCoreId: targetCoreId,
      relatedJournalEntryId: relatedEntry?.id,
      additionalData: additionalData ?? {},
      timestamp: DateTime.now(),
    );

    // Add to context stack for preservation
    _contextStack.add(context);
    
    // Keep stack size manageable (last 10 contexts)
    if (_contextStack.length > 10) {
      _contextStack.removeAt(0);
    }

    _currentContext = context;
    _navigationController.add(context);

    return context;
  }

  /// Creates context for journal-to-core navigation
  CoreNavigationContext createJournalToCoreContext({
    String? targetCoreId,
    JournalEntry? relatedEntry,
    String? triggeredBy,
  }) {
    return createContext(
      sourceScreen: 'journal',
      triggeredBy: triggeredBy ?? 'core_tap',
      targetCoreId: targetCoreId,
      relatedEntry: relatedEntry,
      additionalData: {
        'showJournalConnection': true,
        'highlightRecentChanges': true,
      },
    );
  }

  /// Creates context for core library navigation
  CoreNavigationContext createCoreLibraryContext({
    String? targetCoreId,
    String? triggeredBy,
    Map<String, dynamic>? additionalData,
  }) {
    return createContext(
      sourceScreen: 'core_library',
      triggeredBy: triggeredBy ?? 'navigation',
      targetCoreId: targetCoreId,
      additionalData: additionalData ?? {},
    );
  }

  /// Creates context for "Explore All" navigation from Your Cores widget
  CoreNavigationContext createExploreAllContext({
    JournalEntry? relatedEntry,
    List<String>? highlightCoreIds,
  }) {
    return createContext(
      sourceScreen: 'journal',
      triggeredBy: 'explore_all',
      additionalData: {
        'showAllCores': true,
        'highlightCoreIds': highlightCoreIds ?? [],
        'preserveJournalContext': true,
        'relatedJournalEntryId': relatedEntry?.id,
      },
    );
  }

  /// Preserves current context during screen transitions
  void preserveContext(CoreNavigationContext context) {
    if (_contextStack.isEmpty || _contextStack.last != context) {
      _contextStack.add(context);
      
      // Keep stack size manageable
      if (_contextStack.length > 10) {
        _contextStack.removeAt(0);
      }
    }
    
    _currentContext = context;
  }

  /// Restores context when returning to previous screen
  CoreNavigationContext? restoreContext() {
    if (_contextStack.length > 1) {
      // Remove current context and return to previous
      _contextStack.removeLast();
      final previousContext = _contextStack.last;
      _currentContext = previousContext;
      _navigationController.add(previousContext);
      return previousContext;
    }
    return null;
  }

  /// Gets the previous context without removing it from stack
  CoreNavigationContext? getPreviousContext() {
    if (_contextStack.length > 1) {
      return _contextStack[_contextStack.length - 2];
    }
    return null;
  }

  /// Clears navigation context (useful for fresh starts)
  void clearContext() {
    _contextStack.clear();
    _currentContext = null;
  }

  /// Checks if we can navigate back based on context stack
  bool canNavigateBack() {
    return _contextStack.length > 1;
  }

  /// Gets context for a specific core ID from history
  CoreNavigationContext? getContextForCore(String coreId) {
    for (int i = _contextStack.length - 1; i >= 0; i--) {
      final context = _contextStack[i];
      if (context.targetCoreId == coreId) {
        return context;
      }
    }
    return null;
  }

  /// Updates current context with additional data
  void updateCurrentContext(Map<String, dynamic> additionalData) {
    if (_currentContext != null) {
      final updatedData = Map<String, dynamic>.from(_currentContext!.additionalData);
      updatedData.addAll(additionalData);
      
      final updatedContext = CoreNavigationContext(
        sourceScreen: _currentContext!.sourceScreen,
        triggeredBy: _currentContext!.triggeredBy,
        targetCoreId: _currentContext!.targetCoreId,
        relatedJournalEntryId: _currentContext!.relatedJournalEntryId,
        additionalData: updatedData,
        timestamp: _currentContext!.timestamp,
      );
      
      // Replace current context in stack
      if (_contextStack.isNotEmpty) {
        _contextStack[_contextStack.length - 1] = updatedContext;
      }
      
      _currentContext = updatedContext;
      _navigationController.add(updatedContext);
    }
  }

  /// Checks if current navigation came from journal screen
  bool isFromJournal() {
    return _currentContext?.sourceScreen == 'journal';
  }

  /// Checks if current navigation came from core library
  bool isFromCoreLibrary() {
    return _currentContext?.sourceScreen == 'core_library';
  }

  /// Gets related journal entry ID from current context
  String? getRelatedJournalEntryId() {
    return _currentContext?.relatedJournalEntryId;
  }

  /// Checks if context indicates we should show journal connections
  bool shouldShowJournalConnection() {
    return _currentContext?.additionalData['showJournalConnection'] == true;
  }

  /// Checks if context indicates we should highlight recent changes
  bool shouldHighlightRecentChanges() {
    return _currentContext?.additionalData['highlightRecentChanges'] == true;
  }

  /// Gets list of core IDs to highlight from context
  List<String> getCoreIdsToHighlight() {
    final highlightIds = _currentContext?.additionalData['highlightCoreIds'];
    if (highlightIds is List) {
      return List<String>.from(highlightIds);
    }
    return [];
  }

  /// Navigates to a specific core with context-aware routing
  Future<void> navigateToCore(
    BuildContext context,
    String coreId, {
    CoreNavigationContext? navigationContext,
    bool replace = false,
  }) async {
    // Create context if not provided
    final navContext = navigationContext ?? createContext(
      sourceScreen: 'unknown',
      triggeredBy: 'direct_navigation',
      targetCoreId: coreId,
    );

    // Preserve context
    preserveContext(navContext);

    // Navigate to core detail screen
    if (replace) {
      await Navigator.of(context).pushReplacementNamed(
        '/core-detail',
        arguments: {
          'coreId': coreId,
          'context': navContext,
        },
      );
    } else {
      await Navigator.of(context).pushNamed(
        '/core-detail',
        arguments: {
          'coreId': coreId,
          'context': navContext,
        },
      );
    }
  }

  /// Navigates to all cores view (Core Library) with context
  Future<void> navigateToAllCores(
    BuildContext context, {
    CoreNavigationContext? navigationContext,
    bool replace = false,
  }) async {
    // Create context if not provided
    final navContext = navigationContext ?? createExploreAllContext();

    // Preserve context
    preserveContext(navContext);

    // Navigate to core library screen
    if (replace) {
      await Navigator.of(context).pushReplacementNamed(
        '/core-library',
        arguments: {
          'context': navContext,
        },
      );
    } else {
      await Navigator.of(context).pushNamed(
        '/core-library',
        arguments: {
          'context': navContext,
        },
      );
    }
  }

  /// Handles deep link navigation to core details
  Future<void> handleDeepLink(
    BuildContext context,
    String deepLink, {
    Map<String, dynamic>? parameters,
  }) async {
    final uri = Uri.parse(deepLink);
    
    // Handle core detail deep links: /core/{coreId}
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'core') {
      final coreId = uri.pathSegments[1];
      
      // Extract parameters from query string
      final queryParams = uri.queryParameters;
      final sourceScreen = queryParams['source'] ?? 'deep_link';
      final triggeredBy = queryParams['trigger'] ?? 'deep_link';
      final relatedEntryId = queryParams['entry'];
      
      // Create navigation context from deep link
      final navContext = createContext(
        sourceScreen: sourceScreen,
        triggeredBy: triggeredBy,
        targetCoreId: coreId,
        additionalData: {
          'isDeepLink': true,
          'deepLinkUrl': deepLink,
          'relatedJournalEntryId': relatedEntryId,
          ...?parameters,
        },
      );

      await navigateToCore(context, coreId, navigationContext: navContext);
    }
    // Handle core library deep links: /cores or /core-library
    else if (uri.pathSegments.isNotEmpty && 
             (uri.pathSegments[0] == 'cores' || uri.pathSegments[0] == 'core-library')) {
      
      final queryParams = uri.queryParameters;
      final sourceScreen = queryParams['source'] ?? 'deep_link';
      final highlightCores = queryParams['highlight']?.split(',') ?? [];
      
      final navContext = createContext(
        sourceScreen: sourceScreen,
        triggeredBy: 'deep_link',
        additionalData: {
          'isDeepLink': true,
          'deepLinkUrl': deepLink,
          'highlightCoreIds': highlightCores,
          'showAllCores': true,
          ...?parameters,
        },
      );

      await navigateToAllCores(context, navigationContext: navContext);
    }
  }

  /// Generates deep link URL for a specific core
  String generateCoreDeepLink(
    String coreId, {
    String? sourceScreen,
    String? relatedEntryId,
    Map<String, String>? additionalParams,
  }) {
    final uri = Uri(
      path: '/core/$coreId',
      queryParameters: {
        if (sourceScreen != null) 'source': sourceScreen,
        if (relatedEntryId != null) 'entry': relatedEntryId,
        'trigger': 'deep_link',
        ...?additionalParams,
      },
    );
    
    return uri.toString();
  }

  /// Generates deep link URL for core library
  String generateCoreLibraryDeepLink({
    String? sourceScreen,
    List<String>? highlightCores,
    Map<String, String>? additionalParams,
  }) {
    final uri = Uri(
      path: '/core-library',
      queryParameters: {
        if (sourceScreen != null) 'source': sourceScreen,
        if (highlightCores != null && highlightCores.isNotEmpty) 
          'highlight': highlightCores.join(','),
        'trigger': 'deep_link',
        ...?additionalParams,
      },
    );
    
    return uri.toString();
  }

  /// Navigates back with context restoration
  Future<bool> navigateBack(BuildContext context) async {
    final previousContext = restoreContext();
    
    if (previousContext != null) {
      // Navigate back with preserved context
      Navigator.of(context).pop();
      return true;
    }
    
    // No context to restore, use default back navigation
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return true;
    }
    
    return false;
  }

  /// Handles parameter passing for core-specific navigation
  Map<String, dynamic> buildNavigationArguments({
    required String coreId,
    CoreNavigationContext? context,
    Map<String, dynamic>? additionalArgs,
  }) {
    return {
      'coreId': coreId,
      'context': context ?? _currentContext,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalArgs,
    };
  }

  /// Extracts navigation arguments from route settings
  static Map<String, dynamic>? extractNavigationArguments(RouteSettings settings) {
    if (settings.arguments is Map<String, dynamic>) {
      return settings.arguments as Map<String, dynamic>;
    }
    return null;
  }

  /// Extracts core ID from navigation arguments
  static String? extractCoreId(RouteSettings settings) {
    final args = extractNavigationArguments(settings);
    return args?['coreId'] as String?;
  }

  /// Extracts navigation context from route arguments
  static CoreNavigationContext? extractNavigationContext(RouteSettings settings) {
    final args = extractNavigationArguments(settings);
    return args?['context'] as CoreNavigationContext?;
  }

  /// Creates custom page transition for core navigation
  PageRouteBuilder<T> createCoreTransition<T>(
    Widget destination,
    CoreNavigationContext context, {
    Duration duration = const Duration(milliseconds: 300),
    Duration reverseDuration = const Duration(milliseconds: 250),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      transitionsBuilder: (buildContext, animation, secondaryAnimation, child) {
        return _buildContextualTransition(
          buildContext,
          animation,
          secondaryAnimation,
          child,
          navigationContext: context,
        );
      },
    );
  }

  /// Builds contextual transition based on navigation source
  Widget _buildContextualTransition(
    BuildContext buildContext,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child, {
    required CoreNavigationContext navigationContext,
  }) {
    // Choose transition based on source screen
    switch (navigationContext.sourceScreen) {
      case 'journal':
        return _buildJournalToCoreTransition(animation, secondaryAnimation, child);
      case 'core_library':
        return _buildCoreLibraryTransition(animation, secondaryAnimation, child);
      default:
        return _buildDefaultTransition(animation, secondaryAnimation, child);
    }
  }

  /// Smooth slide transition from journal to core
  Widget _buildJournalToCoreTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Slide from right with fade
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeInOutCubic;

    final slideAnimation = Tween(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: curve,
    ));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }

  /// Transition within core library screens
  Widget _buildCoreLibraryTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Scale and fade transition for core library navigation
    final scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    ));

    return ScaleTransition(
      scale: scaleAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }

  /// Default transition for other navigation sources
  Widget _buildDefaultTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Simple fade transition
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// Creates hero animation for core icons and progress indicators
  Widget createCoreHeroTransition({
    required String heroTag,
    required Widget child,
    String? coreId,
  }) {
    return Hero(
      tag: heroTag,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        return _buildHeroFlightWidget(
          animation,
          flightDirection,
          child,
          coreId: coreId,
        );
      },
      child: child,
    );
  }

  /// Builds custom hero flight animation
  Widget _buildHeroFlightWidget(
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    Widget child, {
    String? coreId,
  }) {
    // Add rotation and scale during hero flight
    final rotationAnimation = Tween<double>(
      begin: 0.0,
      end: flightDirection == HeroFlightDirection.push ? 0.1 : -0.1,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    final scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
    ));

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: rotationAnimation.value,
          child: Transform.scale(
            scale: scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Creates smooth transition for core progress indicators
  Widget createProgressIndicatorTransition({
    required Animation<double> animation,
    required double fromProgress,
    required double toProgress,
    required Widget Function(double progress) builder,
  }) {
    final progressAnimation = Tween<double>(
      begin: fromProgress,
      end: toProgress,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
    ));

    return AnimatedBuilder(
      animation: progressAnimation,
      builder: (context, child) {
        return builder(progressAnimation.value);
      },
    );
  }

  /// Enhanced navigation with custom transitions
  Future<void> navigateToCoreWithTransition(
    BuildContext context,
    String coreId, {
    CoreNavigationContext? navigationContext,
    bool replace = false,
  }) async {
    // Create context if not provided
    final navContext = navigationContext ?? createContext(
      sourceScreen: 'unknown',
      triggeredBy: 'direct_navigation',
      targetCoreId: coreId,
    );

    // Preserve context
    preserveContext(navContext);

    // Create custom transition route
    final route = createCoreTransition<void>(
      // For now, use CoreLibraryScreen as destination
      // This will be replaced with dedicated CoreDetailScreen later
      const CoreLibraryScreen(),
      navContext,
    );

    // Navigate with custom transition
    if (replace) {
      await Navigator.of(context).pushReplacement(route);
    } else {
      await Navigator.of(context).push(route);
    }
  }

  /// Enhanced navigation to all cores with transition
  Future<void> navigateToAllCoresWithTransition(
    BuildContext context, {
    CoreNavigationContext? navigationContext,
    bool replace = false,
  }) async {
    // Create context if not provided
    final navContext = navigationContext ?? createExploreAllContext();

    // Preserve context
    preserveContext(navContext);

    // Create custom transition route
    final route = createCoreTransition<void>(
      const CoreLibraryScreen(),
      navContext,
    );

    // Navigate with custom transition
    if (replace) {
      await Navigator.of(context).pushReplacement(route);
    } else {
      await Navigator.of(context).push(route);
    }
  }

  /// Disposes resources
  void dispose() {
    _navigationController.close();
    _contextStack.clear();
    _currentContext = null;
  }
}
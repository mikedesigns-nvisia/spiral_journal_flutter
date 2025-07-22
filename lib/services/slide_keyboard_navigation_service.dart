import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/emotional_mirror_slide_controller.dart';
import 'accessibility_service.dart';

/// Service for handling keyboard navigation within slides
class SlideKeyboardNavigationService {
  static final SlideKeyboardNavigationService _instance = SlideKeyboardNavigationService._internal();
  factory SlideKeyboardNavigationService() => _instance;
  SlideKeyboardNavigationService._internal();

  final AccessibilityService _accessibilityService = AccessibilityService();
  EmotionalMirrorSlideController? _slideController;
  List<FocusNode> _slideFocusNodes = [];
  int _currentFocusIndex = 0;
  bool _isInitialized = false;

  /// Initialize the keyboard navigation service
  Future<void> initialize({
    required EmotionalMirrorSlideController slideController,
  }) async {
    if (_isInitialized) return;
    
    _slideController = slideController;
    await _accessibilityService.initialize();
    _isInitialized = true;
  }

  /// Register focus nodes for the current slide
  void registerSlideFocusNodes(List<FocusNode> focusNodes) {
    _slideFocusNodes = focusNodes;
    _currentFocusIndex = 0;
  }

  /// Handle keyboard events for slide navigation
  bool handleKeyboardEvent(RawKeyEvent event) {
    if (!_isInitialized || _slideController == null) return false;

    if (event is RawKeyDownEvent) {
      return _handleKeyDown(event);
    }
    
    return false;
  }

  /// Handle key down events
  bool _handleKeyDown(RawKeyDownEvent event) {
    final isArrowLeft = event.logicalKey == LogicalKeyboardKey.arrowLeft;
    final isArrowRight = event.logicalKey == LogicalKeyboardKey.arrowRight;
    final isArrowUp = event.logicalKey == LogicalKeyboardKey.arrowUp;
    final isArrowDown = event.logicalKey == LogicalKeyboardKey.arrowDown;
    final isTab = event.logicalKey == LogicalKeyboardKey.tab;
    final isShiftPressed = event.isShiftPressed;
    final isEnter = event.logicalKey == LogicalKeyboardKey.enter;
    final isSpace = event.logicalKey == LogicalKeyboardKey.space;
    final isEscape = event.logicalKey == LogicalKeyboardKey.escape;

    // Handle slide navigation with arrow keys
    if (isArrowLeft || isArrowRight) {
      return _handleSlideNavigation(isArrowLeft, isArrowRight);
    }

    // Handle focus navigation within slide
    if (isTab || isArrowUp || isArrowDown) {
      return _handleFocusNavigation(isTab, isArrowUp, isArrowDown, isShiftPressed);
    }

    // Handle activation keys
    if (isEnter || isSpace) {
      return _handleActivation();
    }

    // Handle escape key
    if (isEscape) {
      return _handleEscape();
    }

    return false;
  }

  /// Handle slide navigation with arrow keys
  bool _handleSlideNavigation(bool isLeft, bool isRight) {
    if (_slideController == null) return false;

    if (isLeft && _slideController!.canGoPrevious) {
      _slideController!.previousSlide();
      _announceSlideNavigation('previous');
      return true;
    } else if (isRight && _slideController!.canGoNext) {
      _slideController!.nextSlide();
      _announceSlideNavigation('next');
      return true;
    } else if ((isLeft && !_slideController!.canGoPrevious) || 
               (isRight && !_slideController!.canGoNext)) {
      // Announce boundary hit
      _announceBoundaryHit(isLeft ? 'first' : 'last');
      return true;
    }

    return false;
  }

  /// Handle focus navigation within slide
  bool _handleFocusNavigation(bool isTab, bool isUp, bool isDown, bool isShiftPressed) {
    if (_slideFocusNodes.isEmpty) return false;

    if (isTab) {
      if (isShiftPressed) {
        _moveFocusPrevious();
      } else {
        _moveFocusNext();
      }
      return true;
    } else if (isUp) {
      _moveFocusPrevious();
      return true;
    } else if (isDown) {
      _moveFocusNext();
      return true;
    }

    return false;
  }

  /// Move focus to next focusable element
  void _moveFocusNext() {
    if (_slideFocusNodes.isEmpty) return;

    _currentFocusIndex = (_currentFocusIndex + 1) % _slideFocusNodes.length;
    _requestFocus();
  }

  /// Move focus to previous focusable element
  void _moveFocusPrevious() {
    if (_slideFocusNodes.isEmpty) return;

    _currentFocusIndex = (_currentFocusIndex - 1 + _slideFocusNodes.length) % _slideFocusNodes.length;
    _requestFocus();
  }

  /// Request focus for current focus node
  void _requestFocus() {
    if (_currentFocusIndex >= 0 && _currentFocusIndex < _slideFocusNodes.length) {
      final focusNode = _slideFocusNodes[_currentFocusIndex];
      if (focusNode.canRequestFocus) {
        focusNode.requestFocus();
        _announceFocusChange();
      }
    }
  }

  /// Handle activation (Enter/Space) keys
  bool _handleActivation() {
    final currentFocus = FocusManager.instance.primaryFocus;
    if (currentFocus != null) {
      // Trigger tap on focused element
      _announceActivation();
      return true;
    }
    return false;
  }

  /// Handle escape key
  bool _handleEscape() {
    // Clear focus or return to slide navigation
    FocusManager.instance.primaryFocus?.unfocus();
    _announceEscape();
    return true;
  }

  /// Create focus node for slide element
  FocusNode createSlideFocusNode({
    required String elementId,
    String? semanticLabel,
    String? hint,
    bool autofocus = false,
  }) {
    return FocusNode(
      debugLabel: elementId,
      canRequestFocus: true,
      skipTraversal: false,
    );
  }

  /// Get keyboard navigation instructions
  String getKeyboardNavigationInstructions() {
    return 'Use left and right arrow keys to navigate between slides. '
           'Use Tab or up/down arrows to navigate within a slide. '
           'Press Enter or Space to activate focused elements. '
           'Press Escape to clear focus.';
  }

  /// Get slide-specific keyboard shortcuts
  Map<String, String> getSlideKeyboardShortcuts() {
    return {
      'Left Arrow': 'Previous slide',
      'Right Arrow': 'Next slide',
      'Tab': 'Next element in slide',
      'Shift + Tab': 'Previous element in slide',
      'Up Arrow': 'Previous element in slide',
      'Down Arrow': 'Next element in slide',
      'Enter/Space': 'Activate focused element',
      'Escape': 'Clear focus',
    };
  }

  /// Announce slide navigation for screen readers
  void _announceSlideNavigation(String direction) {
    if (_slideController == null) return;

    final slideConfig = _slideController!.currentSlideConfig;
    final slideNumber = _slideController!.currentSlide + 1;
    final totalSlides = _slideController!.totalSlides;

    _accessibilityService.announceToScreenReader(
      'Navigated to $direction slide. Slide $slideNumber of $totalSlides: ${slideConfig.title}',
      assertiveness: Assertiveness.polite,
    );
  }

  /// Announce boundary hit for screen readers
  void _announceBoundaryHit(String boundary) {
    _accessibilityService.announceToScreenReader(
      'Reached $boundary slide. Cannot navigate further in this direction.',
      assertiveness: Assertiveness.polite,
    );
  }

  /// Announce focus change for screen readers
  void _announceFocusChange() {
    if (_currentFocusIndex >= 0 && _currentFocusIndex < _slideFocusNodes.length) {
      final focusNode = _slideFocusNodes[_currentFocusIndex];
      final elementNumber = _currentFocusIndex + 1;
      final totalElements = _slideFocusNodes.length;

      _accessibilityService.announceToScreenReader(
        'Focused on element $elementNumber of $totalElements',
        assertiveness: Assertiveness.polite,
      );
    }
  }

  /// Announce activation for screen readers
  void _announceActivation() {
    _accessibilityService.announceToScreenReader(
      'Activated focused element',
      assertiveness: Assertiveness.polite,
    );
  }

  /// Announce escape action for screen readers
  void _announceEscape() {
    _accessibilityService.announceToScreenReader(
      'Focus cleared. Use arrow keys to navigate slides.',
      assertiveness: Assertiveness.polite,
    );
  }

  /// Get current focus index
  int get currentFocusIndex => _currentFocusIndex;

  /// Get total focusable elements in current slide
  int get totalFocusableElements => _slideFocusNodes.length;

  /// Check if keyboard navigation is available
  bool get isKeyboardNavigationAvailable => _isInitialized && _slideController != null;

  /// Reset focus to first element
  void resetFocus() {
    _currentFocusIndex = 0;
    if (_slideFocusNodes.isNotEmpty) {
      _requestFocus();
    }
  }

  /// Clear all focus nodes
  void clearFocusNodes() {
    _slideFocusNodes.clear();
    _currentFocusIndex = 0;
  }

  /// Dispose of resources
  void dispose() {
    clearFocusNodes();
    _slideController = null;
    _isInitialized = false;
  }
}

/// Widget that provides keyboard navigation support for slides
class KeyboardNavigationWrapper extends StatefulWidget {
  final Widget child;
  final EmotionalMirrorSlideController slideController;
  final List<FocusNode>? focusNodes;

  const KeyboardNavigationWrapper({
    super.key,
    required this.child,
    required this.slideController,
    this.focusNodes,
  });

  @override
  State<KeyboardNavigationWrapper> createState() => _KeyboardNavigationWrapperState();
}

class _KeyboardNavigationWrapperState extends State<KeyboardNavigationWrapper> {
  final SlideKeyboardNavigationService _keyboardService = SlideKeyboardNavigationService();
  late FocusNode _wrapperFocusNode;

  @override
  void initState() {
    super.initState();
    _wrapperFocusNode = FocusNode(debugLabel: 'slide_keyboard_wrapper');
    _initializeKeyboardNavigation();
  }

  Future<void> _initializeKeyboardNavigation() async {
    await _keyboardService.initialize(slideController: widget.slideController);
    
    if (widget.focusNodes != null) {
      _keyboardService.registerSlideFocusNodes(widget.focusNodes!);
    }
  }

  @override
  void didUpdateWidget(KeyboardNavigationWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.focusNodes != oldWidget.focusNodes && widget.focusNodes != null) {
      _keyboardService.registerSlideFocusNodes(widget.focusNodes!);
    }
  }

  @override
  void dispose() {
    _wrapperFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _wrapperFocusNode,
      onKey: _keyboardService.handleKeyboardEvent,
      child: widget.child,
    );
  }
}

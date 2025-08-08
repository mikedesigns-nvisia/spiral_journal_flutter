# Design Document

## Overview

The Core Integration Enhancement redesigns the core system architecture to create a unified, seamless experience between the Your Cores widget and Core Library screen. The design focuses on centralizing data management through the CoreProvider, implementing contextual navigation, and creating real-time synchronization across all core displays.

## Architecture

### Current State Analysis

**Problems with Current Architecture:**
- Your Cores widget uses CoreProvider while Core Library screen uses CoreLibraryService directly
- No shared state management between components
- Navigation lacks context and deep linking
- Data synchronization issues between different core displays
- Inconsistent loading and error states

**Proposed Architecture:**
```
┌─────────────────────────────────────────────────────────────┐
│                    Unified Core System                      │
├─────────────────────────────────────────────────────────────┤
│  CoreProvider (Enhanced)                                    │
│  ├── Centralized state management                           │
│  ├── Real-time synchronization                              │
│  ├── Context-aware navigation                               │
│  └── Performance optimization                               │
├─────────────────────────────────────────────────────────────┤
│  CoreLibraryService (Refactored)                           │
│  ├── Data persistence layer                                 │
│  ├── AI analysis integration                                │
│  ├── Background sync operations                             │
│  └── Cache management                                       │
├─────────────────────────────────────────────────────────────┤
│  Navigation Context Service                                 │
│  ├── Deep linking support                                   │
│  ├── Context preservation                                   │
│  ├── Transition animations                                  │
│  └── State restoration                                      │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow Architecture

```
Journal Entry → AI Analysis → Core Updates → Provider Notification → UI Updates
     ↓              ↓             ↓              ↓                    ↓
  Content      Emotional     Level Changes   State Sync        Real-time
  Analysis     Insights      Calculations    Broadcast         Refresh
```

## Components and Interfaces

### Enhanced CoreProvider

**Purpose:** Centralized state management for all core-related data and operations.

**Key Enhancements:**
```dart
class CoreProvider with ChangeNotifier {
  // Enhanced state management
  List<EmotionalCore> _allCores = [];
  Map<String, CoreDetailContext> _coreContexts = {};
  CoreNavigationState _navigationState = CoreNavigationState.initial();
  
  // Real-time synchronization
  StreamSubscription? _coreUpdateSubscription;
  Timer? _syncTimer;
  
  // Context-aware methods
  Future<void> navigateToCore(String coreId, {CoreNavigationContext? context});
  Future<void> updateCoreWithContext(String coreId, JournalEntry? relatedEntry);
  Stream<CoreUpdateEvent> get coreUpdateStream;
  
  // Performance optimization
  Future<void> preloadCoreDetails(List<String> coreIds);
  void invalidateCache(String coreId);
}
```

**Responsibilities:**
- Manage all core data through single source of truth
- Handle real-time updates and synchronization
- Provide context-aware navigation support
- Optimize performance with caching and preloading
- Broadcast state changes to all listening widgets

### Core Navigation Context Service

**Purpose:** Manage contextual navigation between core displays with state preservation.

```dart
class CoreNavigationContextService {
  // Navigation context preservation
  CoreNavigationContext createContext({
    String? sourceScreen,
    String? triggeredBy,
    JournalEntry? relatedEntry,
    Map<String, dynamic>? additionalData,
  });
  
  // Deep linking support
  Future<void> navigateToCore(String coreId, CoreNavigationContext context);
  Future<void> navigateToAllCores(CoreNavigationContext context);
  
  // Transition management
  PageRouteBuilder createCoreTransition(Widget destination, CoreNavigationContext context);
}
```

### Unified Core Widget System

**Your Cores Widget (Enhanced):**
```dart
class YourCoresCard extends StatelessWidget {
  // Enhanced with context-aware navigation
  void _onCorePressed(EmotionalCore core) {
    final context = CoreNavigationContext(
      sourceScreen: 'journal',
      triggeredBy: 'core_tap',
      targetCoreId: core.id,
    );
    Provider.of<CoreProvider>(context, listen: false)
        .navigateToCore(core.id, context: context);
  }
  
  // Real-time update indicators
  Widget _buildRecentChangeIndicator(EmotionalCore core) {
    return AnimatedContainer(
      // Show recent changes with smooth animations
    );
  }
}
```

**Core Library Screen (Refactored):**
```dart
class CoreLibraryScreen extends StatefulWidget {
  final CoreNavigationContext? navigationContext;
  
  // Remove direct CoreLibraryService usage
  // Use CoreProvider exclusively for data access
}
```

### Real-time Synchronization System

**Core Update Event System:**
```dart
enum CoreUpdateEventType {
  levelChanged,
  trendChanged,
  milestoneAchieved,
  insightGenerated,
  analysisCompleted,
}

class CoreUpdateEvent {
  final String coreId;
  final CoreUpdateEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final JournalEntry? relatedEntry;
}
```

**Synchronization Manager:**
```dart
class CoreSynchronizationManager {
  // Broadcast updates to all listening components
  final StreamController<CoreUpdateEvent> _updateController;
  
  // Batch updates for performance
  void batchUpdateCores(List<CoreUpdateEvent> events);
  
  // Conflict resolution
  Future<void> resolveCoreConflicts(List<EmotionalCore> conflictingCores);
}
```

## Data Models

### Enhanced Core Models

**CoreNavigationContext:**
```dart
class CoreNavigationContext {
  final String sourceScreen;
  final String? triggeredBy;
  final String? targetCoreId;
  final JournalEntry? relatedEntry;
  final Map<String, dynamic> additionalData;
  final DateTime timestamp;
}
```

**CoreDetailContext:**
```dart
class CoreDetailContext {
  final EmotionalCore core;
  final List<JournalEntry> relatedEntries;
  final List<CoreUpdateEvent> recentUpdates;
  final CoreInsight? latestInsight;
  final List<CoreMilestone> upcomingMilestones;
}
```

**CoreUpdateMetadata:**
```dart
class CoreUpdateMetadata {
  final String updateSource; // 'ai_analysis', 'manual', 'background_sync'
  final double previousLevel;
  final double newLevel;
  final String? triggerReason;
  final JournalEntry? relatedEntry;
}
```

## Error Handling

### Unified Error Management

**Core Error Types:**
```dart
enum CoreErrorType {
  dataLoadFailure,
  syncFailure,
  navigationError,
  analysisError,
  persistenceError,
}

class CoreError {
  final CoreErrorType type;
  final String message;
  final String? coreId;
  final dynamic originalError;
  final bool isRecoverable;
}
```

**Error Recovery Strategies:**
- **Data Load Failures:** Use cached data with refresh indicator
- **Sync Failures:** Queue updates for retry with exponential backoff
- **Navigation Errors:** Graceful fallback to default core library view
- **Analysis Errors:** Continue with existing core data, log for debugging
- **Persistence Errors:** Maintain in-memory state, retry persistence

### Graceful Degradation

**Offline Support:**
- Cache core data locally for offline viewing
- Queue updates when connectivity is restored
- Show appropriate offline indicators

**Performance Degradation:**
- Progressive loading for large core datasets
- Skeleton screens during data loading
- Optimistic updates with rollback capability

## Testing Strategy

### Unit Testing

**CoreProvider Tests:**
- State management correctness
- Real-time synchronization accuracy
- Context preservation during navigation
- Error handling and recovery
- Performance optimization effectiveness

**Navigation Context Tests:**
- Context creation and preservation
- Deep linking functionality
- Transition animation correctness
- State restoration accuracy

### Integration Testing

**Core System Integration:**
- End-to-end core update flow
- Journal-to-core impact tracking
- Cross-screen data consistency
- Real-time synchronization across components

**User Journey Testing:**
- Journal → Your Cores → Core Library flow
- Core detail navigation and return
- Multi-screen core data consistency
- Performance under various conditions

### Performance Testing

**Load Testing:**
- Large numbers of cores and entries
- Rapid core updates and synchronization
- Memory usage optimization
- Battery impact assessment

**Responsiveness Testing:**
- UI update latency measurement
- Animation smoothness verification
- Touch response time validation
- Accessibility performance testing

## Implementation Phases

### Phase 1: Core Provider Enhancement
- Refactor CoreProvider for centralized state management
- Implement real-time synchronization infrastructure
- Add context-aware navigation support
- Create unified error handling system

### Phase 2: Navigation Integration
- Implement CoreNavigationContextService
- Add deep linking support for core details
- Create smooth transition animations
- Integrate context preservation

### Phase 3: UI Unification
- Refactor Core Library screen to use CoreProvider
- Enhance Your Cores widget with context awareness
- Implement real-time update indicators
- Add performance optimizations

### Phase 4: Polish and Optimization
- Fine-tune animations and transitions
- Optimize performance and memory usage
- Enhance accessibility support
- Add comprehensive error recovery

## Security Considerations

**Data Privacy:**
- Ensure core data encryption at rest
- Secure transmission of core updates
- User consent for data synchronization
- Privacy-preserving analytics

**Data Integrity:**
- Validate core data consistency
- Prevent data corruption during updates
- Secure backup and recovery mechanisms
- Audit trail for core changes

## Accessibility Enhancements

**Screen Reader Support:**
- Comprehensive VoiceOver/TalkBack descriptions
- Context-aware announcements for core changes
- Logical navigation order across core displays
- Alternative text for visual core indicators

**Motor Accessibility:**
- Appropriate touch target sizes (minimum 44pt)
- Gesture alternatives for complex interactions
- Voice control compatibility
- Switch control navigation support

**Visual Accessibility:**
- High contrast mode compatibility
- Dynamic type support for all text
- Color-blind friendly core indicators
- Reduced motion options for animations

## Performance Optimization

**Memory Management:**
- Efficient core data caching strategies
- Lazy loading of detailed core information
- Proper disposal of resources and subscriptions
- Memory leak prevention in real-time updates

**Network Optimization:**
- Batch core update requests
- Intelligent sync scheduling
- Offline-first architecture
- Compression for core data transmission

**UI Performance:**
- Smooth 60fps animations
- Efficient widget rebuilding strategies
- Image and asset optimization
- Background processing for heavy operations
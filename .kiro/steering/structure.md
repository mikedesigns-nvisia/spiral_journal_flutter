# Project Structure

## Root Directory Organization
```
spiral_journal/
├── lib/                    # Main application code
├── macos/                  # macOS platform-specific files
├── test/                   # Unit and widget tests
├── pubspec.yaml           # Dependencies and project config
├── README.md              # Project documentation
└── analysis_options.yaml # Dart analyzer configuration
```

## Core Application Structure (`lib/`)
```
lib/
├── main.dart              # App entry point and MaterialApp setup
├── theme/
│   └── app_theme.dart     # Centralized Material Design 3 theming
├── models/
│   ├── journal_entry.dart # Journal entry data model with JSON serialization
│   └── core.dart         # Emotional core models and related classes
├── screens/
│   ├── main_screen.dart           # Bottom navigation container
│   ├── journal_screen.dart        # Writing interface with mood selection
│   ├── journal_history_screen.dart # Entry timeline and search
│   ├── emotional_mirror_screen.dart # Mood analysis dashboard
│   ├── core_library_screen.dart    # Personal development tracking
│   └── settings_screen.dart        # App preferences and configuration
└── widgets/
    ├── journal_input.dart         # Text input component
    ├── mood_selector.dart         # Mood selection chips
    ├── mind_reflection_card.dart  # AI insights display card
    └── your_cores_card.dart       # Core progress tracking widget
```

## Navigation Architecture
- **Bottom Navigation**: 5-tab structure (Journal, History, Mirror, Insights, Settings)
- **Screen Hierarchy**: MainScreen → Individual feature screens
- **State Management**: StatefulWidget pattern with local state

## File Naming Conventions
- **Screens**: `*_screen.dart` - Full-page UI components
- **Widgets**: `*.dart` - Reusable UI components
- **Models**: `*.dart` - Data structures and business logic
- **Theme**: `app_theme.dart` - Centralized styling

## Code Organization Principles
- **Single Responsibility**: Each file has a clear, focused purpose
- **Material Design Consistency**: All UI follows Material 3 guidelines
- **Reusable Components**: Widgets are designed for reuse across screens
- **Type Safety**: Strong typing with proper model classes
- **JSON Serialization**: Models support data persistence and API integration

## Platform-Specific Files
- **macOS**: Native platform configuration in `macos/` directory
- **Build Artifacts**: Generated files in `.dart_tool/` and `build/` (ignored in git)
- **Dependencies**: Managed through `pubspec.yaml` and `.flutter-plugins-dependencies`
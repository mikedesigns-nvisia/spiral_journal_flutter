# Technology Stack

## Framework & Platform
- **Flutter**: Cross-platform mobile/desktop app framework (SDK >=3.0.0)
- **Dart**: Programming language (>=3.0.0)
- **Material Design 3**: UI design system with custom theming

## Key Dependencies
- `google_fonts`: Typography (Noto Sans JP for international accessibility)
- `material_color_utilities`: Advanced Material Design color utilities
- `intl`: Internationalization support
- `cupertino_icons`: iOS-style icons

## Development Tools
- `flutter_test`: Testing framework
- `flutter_lints`: Code quality and style enforcement

## Design System
- **Color Palette**: Warm oranges (#865219, #FDB876) with cream backgrounds (#FFF8F5, #FAEBE0)
- **Typography**: Noto Sans JP with weights 400-700
- **Components**: Material 3 cards, chips, navigation, buttons with custom theming

## Common Commands

### Setup & Installation
```bash
flutter pub get                    # Install dependencies
flutter pub upgrade               # Update dependencies
```

### Development
```bash
flutter run -d macos             # Run on macOS
flutter run                      # Run on default device
flutter run --hot                # Enable hot reload
flutter devices                  # List available devices
```

### Code Quality
```bash
flutter analyze                  # Static analysis
flutter test                     # Run unit tests
dart format .                    # Format code
```

### Build & Release
```bash
flutter build macos             # Build for macOS
flutter build apk               # Build Android APK
flutter build ios               # Build for iOS
```

## Architecture Patterns
- **StatefulWidget**: Primary state management pattern
- **Material Theme**: Centralized theming via `AppTheme` class
- **Model Classes**: Data structures with JSON serialization
- **Screen-Widget Separation**: Clear separation between screens and reusable widgets
# Spiral Journal - Flutter Material Design Implementation

A beautiful journaling app with emotional intelligence tracking, built with Flutter and Material Design 3.

## ✨ Features

### 📝 **Main Journal Screen**
- Interactive mood selection with custom Material chips
- Rich text journal input with voice memo support
- Mind reflection cards with AI-powered insights
- Your cores tracking with emotional pattern analysis

### 📚 **Journal History Screen**
- Year-based filtering with Material segmented buttons
- Monthly timeline view with entry counts
- Individual entry previews with mood indicators
- Monthly summaries with emotional journey charts

### 🪞 **Emotional Mirror Screen**
- Comprehensive mood overview with gradient visualization
- Emotional balance analysis with custom indicators
- Self-awareness scoring with detailed insights
- Emotional pattern recognition and growth tracking

### 🎯 **Core Library Screen**
- Featured cores with gradient showcases
- Personal core collection with progress tracking
- Discoverable new cores with related suggestions
- Core combinations for enhanced development

### ⚙️ **Settings Screen**
- Account and privacy management
- Journal preferences and reminders
- App customization and theme options
- Help and support resources

## 🎨 Design System

### **Color Palette**
- **Primary**: Warm oranges (#865219, #FDB876, #6A3B01)
- **Background**: Cream tones (#FFF8F5, #FAEBE0, #F2DFD1)
- **Moods**: Happy (#E78B1B), Content (#7AACB3), Creative (#A198DD), etc.
- **Cores**: Optimist (#AFCACD), Reflective (#EBA751), Social (#B1CDAF), etc.

### **Typography**
- **Font Family**: Noto Sans JP
- **Weights**: Regular (400), Medium (500), SemiBold (600), Bold (700)
- **Scale**: 12px - 24px with proper line heights

### **Material Components**
- **Cards**: Elevated with custom shadows and gradients
- **Chips**: FilterChip with mood-based colors
- **Navigation**: BottomNavigationBar with proper theming
- **Buttons**: ElevatedButton with brand colors
- **Text Fields**: Outlined with warm color focus states

## 🏗️ Architecture

### **Project Structure**
```
lib/
├── main.dart                 # App entry point
├── theme/
│   └── app_theme.dart       # Complete Material theme
├── models/
│   ├── journal_entry.dart   # Data models
│   └── core.dart           # Emotional core models
├── screens/
│   ├── main_screen.dart        # Navigation container
│   ├── journal_screen.dart     # Main journaling
│   ├── journal_history_screen.dart  # Entry timeline
│   ├── emotional_mirror_screen.dart # Mood analysis
│   ├── core_library_screen.dart     # Core management
│   └── settings_screen.dart         # App preferences
└── widgets/
    ├── mood_selector.dart      # Mood selection chips
    ├── journal_input.dart      # Text input component
    ├── mind_reflection_card.dart # AI insights card
    └── your_cores_card.dart    # Core tracking widget
```

### **Key Features**
- **Material Design 3**: Latest Material components and theming
- **Custom Color System**: Warm, accessible color palette
- **State Management**: StatefulWidget with proper lifecycle
- **Navigation**: Bottom navigation with 5 main sections
- **Responsive Layout**: Adaptive design for different screen sizes

## 🚀 Getting Started

### **Prerequisites**
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code with Flutter extensions

### **Installation**
1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### **Dependencies**
- `flutter`: SDK
- `material_color_utilities`: Material Design color system
- `intl`: Date formatting and internationalization
- `cupertino_icons`: iOS-style icons

## 📱 Screenshots

The app implements pixel-perfect recreations of the original Motiff designs:
- Warm, accessible color scheme
- Consistent Material Design language
- Beautiful gradients and shadows
- Interactive mood and core tracking
- Comprehensive emotional intelligence features

## 🎯 Material Design Implementation

### **Components Used**
- **FilterChip**: Mood selection and filtering
- **Card**: Content containers with elevation
- **BottomNavigationBar**: Main app navigation
- **TextField**: Journal input with Material styling
- **LinearProgressIndicator**: Core progress tracking
- **ListTile**: Settings and navigation items
- **GridView**: Core library display
- **Container**: Custom gradients and layouts

### **Theme Customization**
- Custom `ColorScheme` with brand colors
- Consistent `TextTheme` with Noto Sans JP
- Material `CardTheme` with custom elevation
- Branded `ElevatedButtonTheme`
- Custom `ChipTheme` for mood selection
- Warm `InputDecorationTheme`

## 🔮 Future Enhancements

- **Data Persistence**: SQLite/Hive integration
- **Cloud Sync**: Firebase backend integration
- **AI Insights**: Enhanced emotional analysis
- **Notifications**: Daily journaling reminders
- **Export**: PDF and text export functionality
- **Dark Theme**: Alternative color scheme
- **Accessibility**: Enhanced screen reader support

---

Built with ❤️ using Flutter and Material Design 3, implementing beautiful Motiff designs with native mobile excellence.

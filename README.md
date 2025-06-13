# 🌟 Spiral Journal - AI-Powered Personal Growth Platform

> **An intelligent journaling app that transforms stream-of-consciousness writing into actionable personal growth insights using Claude AI and real-time personality evolution tracking.**

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B.svg?style=flat&logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28.svg?style=flat&logo=firebase)](https://firebase.google.com)
[![Claude AI](https://img.shields.io/badge/Claude-AI%20Analysis-7C3AED.svg?style=flat)](https://www.anthropic.com/claude)
[![Material Design 3](https://img.shields.io/badge/Material-Design%203-1976D2.svg?style=flat&logo=material-design)](https://m3.material.io)

---

## 📖 **Project Overview**

Spiral Journal revolutionizes personal development by combining natural journaling with advanced AI analysis. Users write freely, and Claude AI extracts emotional patterns, cognitive insights, and growth indicators to evolve their personality "cores" over time.

### 🎯 **Core Philosophy**
- **Stream-of-consciousness first**: Users write naturally without constraints
- **AI-powered insights**: Claude analyzes entries with psychological depth
- **Growth-focused**: Emphasizes strengths, resilience, and positive development
- **Privacy-first**: User data is encrypted and controlled by them
- **Compassionate analysis**: AI provides encouraging, non-judgmental feedback

---

## 🏗️ **Repository Architecture**

### **Project Structure**
```
spiral-mcp-test/
├── spiral-journal/           # React Web Prototype
│   ├── src/components/      # Interactive UI components
│   ├── src/styles/         # Tailwind styling
│   └── public/            # Static assets
│
└── spiral_journal_flutter/  # Flutter Production App
    ├── lib/
    │   ├── models/         # Data structures
    │   ├── services/       # AI & Backend services
    │   ├── screens/        # App screens
    │   ├── widgets/        # Reusable components
    │   └── theme/          # Material Design system
    ├── macos/             # macOS platform config
    └── test/              # Unit tests
```

### **Development Branches**

#### 🌱 **`main` Branch** *(Current)*
- **Purpose**: Foundation with Material Design implementation
- **Features**: 
  - Complete UI/UX implementation with Material Design 3
  - Static journal screens with dummy data
  - Professional color system and typography
  - Responsive layout with bottom navigation
  - Beautiful mood selectors and core tracking widgets
- **Status**: ✅ Complete - Solid foundation established

#### 🎨 **`prototype` Branch** 
- **Purpose**: Interactive prototype with rich dummy data
- **Features**: 
  - 15+ realistic journal entries with full metadata
  - Advanced search functionality across content/moods/tags
  - Interactive entry cards with detailed modal views
  - Monthly grouping and professional UI polish
- **Status**: ✅ Complete - Production-quality prototype

#### 🚀 **`pre-prod` Branch**
- **Purpose**: Production-ready AI-powered platform
- **Features**:
  - Complete Claude AI integration with specialized analysis
  - Firebase backend with real-time sync
  - User authentication and secure data persistence
  - Dynamic personality core evolution
  - Professional setup and configuration system
- **Status**: ✅ Complete - Ready for production deployment

---

## ✨ **Current Features (Main Branch)**

### **📝 Beautiful Journal Interface**
- Interactive mood selection with custom Material chips
- Rich text journal input with clean, distraction-free design
- Mind reflection cards with placeholder for AI insights
- Your cores tracking with emotional pattern visualization

### **📚 Comprehensive Journal History**
- Year-based filtering with Material segmented buttons
- Monthly timeline view with entry counts
- Individual entry previews with mood indicators
- Monthly summaries with emotional journey tracking

### **🪞 Emotional Mirror Dashboard**
- Comprehensive mood overview with gradient visualization
- Emotional balance analysis with custom indicators
- Self-awareness scoring with detailed insights
- Emotional pattern recognition interface

### **🎯 Core Library Management**
- Featured cores with gradient showcases
- Personal core collection with progress tracking
- Discoverable new cores with related suggestions
- Core combinations for enhanced development

### **⚙️ Professional Settings**
- Account and privacy management
- Journal preferences and reminders
- App customization and theme options
- Help and support resources

---

## 🎨 **Design System**

### **Color Palette**
- **Primary**: Warm oranges (#865219, #FDB876, #6A3B01)
- **Background**: Cream tones (#FFF8F5, #FAEBE0, #F2DFD1)
- **Moods**: Happy (#E78B1B), Content (#7AACB3), Creative (#A198DD)
- **Cores**: Optimist (#AFCACD), Reflective (#EBA751), Social (#B1CDAF)

### **Typography**
- **Font Family**: Noto Sans JP for international accessibility
- **Weights**: Regular (400), Medium (500), SemiBold (600), Bold (700)
- **Scale**: 12px - 24px with proper line heights

### **Material Design 3 Implementation**
- **Cards**: Elevated with custom shadows and gradients
- **Chips**: FilterChip with mood-based colors
- **Navigation**: BottomNavigationBar with proper theming
- **Buttons**: ElevatedButton with brand colors
- **Text Fields**: Outlined with warm color focus states

---

## 🧠 **AI Analysis Pipeline** *(Available in Pre-Prod Branch)*

### **Claude AI Integration**
Advanced AI transforms journaling into deep personal insights:

#### **1. Emotional Intelligence Analysis**
```
Input: "Woke up feeling anxious about work presentation..."
Output: {
  primary_emotions: ["anxious", "determined"],
  emotional_intensity: 7.2,
  coping_mechanisms: ["breathing exercises", "preparation"],
  emotional_strengths: ["self-awareness", "proactive planning"]
}
```

#### **2. Cognitive Pattern Recognition**
- **Thinking Styles**: Analytical, creative, problem-solving, reflective
- **Growth Mindset Indicators**: Learning orientation, resilience signals
- **Self-Awareness Signs**: Metacognitive insights, emotional regulation

#### **3. Personality Core Evolution**
Real-time updates to six core dimensions:
- **Optimism**: Positive outlook and hope for the future
- **Resilience**: Ability to bounce back from challenges  
- **Self-Awareness**: Understanding of thoughts and emotions
- **Creativity**: Innovative thinking and expression
- **Social Connection**: Ability to relate and connect with others
- **Growth Mindset**: Openness to learning and development

---

## 🔧 **Technical Architecture**

### **Frontend Structure**
```dart
lib/
├── main.dart                    # App initialization
├── theme/
│   └── app_theme.dart          # Complete Material theme
├── models/
│   ├── journal_entry.dart      # Entry data models
│   └── core.dart              # Emotional core models
├── screens/
│   ├── main_screen.dart        # Navigation container
│   ├── journal_screen.dart     # Writing interface
│   ├── journal_history_screen.dart # Entry timeline
│   ├── emotional_mirror_screen.dart # Mood analysis
│   ├── core_library_screen.dart     # Core management
│   └── settings_screen.dart          # App preferences
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

---

## 🚀 **Getting Started**

### **Prerequisites**
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code with Flutter extensions

### **Installation**

#### **1. Clone Repository**
```bash
git clone <repository-url>
cd spiral-mcp-test/spiral_journal_flutter
```

#### **2. Install Dependencies**
```bash
flutter pub get
```

#### **3. Run the App**
```bash
flutter run -d macos  # For macOS
flutter run           # For other platforms
```

### **Dependencies**
```yaml
dependencies:
  flutter: sdk
  material_color_utilities: ^0.11.1
  intl: ^0.19.0
  google_fonts: ^6.1.0
  cupertino_icons: ^1.0.2
```

---

## 📱 **Screenshots**

The app implements pixel-perfect recreations of the original Motiff designs:
- Warm, accessible color scheme
- Consistent Material Design language
- Beautiful gradients and shadows
- Interactive mood and core tracking
- Comprehensive emotional intelligence features

---

## 🌟 **Branch Progression**

### **🎯 Current Status:**
- **Main Branch**: Complete Material Design foundation ✅
- **Prototype Branch**: Interactive prototype with rich data ✅  
- **Pre-Prod Branch**: Full AI-powered production platform ✅

### **🚀 Evolution Path:**
1. **Foundation** (main) → Beautiful, functional UI
2. **Prototype** (prototype) → Interactive demo with realistic data
3. **Production** (pre-prod) → AI-powered platform with Claude integration

---

## 🔮 **Future Enhancements**

### **Planned Features**
- Real-time analysis as users type
- Advanced trend visualization charts
- Data export capabilities
- Push notifications for journaling reminders
- Dark theme implementation
- Voice journaling integration

### **AI Capabilities** *(Available in Pre-Prod)*
- Claude AI emotional intelligence analysis
- Dynamic personality core evolution
- Personalized growth insights
- Pattern recognition across entries
- Compassionate, encouraging feedback

---

## 🎯 **Material Design Implementation**

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

---

## 🤝 **Contributing**

### **Development Workflow**
1. **Foundation Work**: Contribute to `main` branch
2. **Interactive Features**: Work on `prototype` branch  
3. **AI Integration**: Develop on `pre-prod` branch
4. **Testing**: Use appropriate branch for testing level

### **Code Standards**
- Flutter/Dart style guide compliance
- Material Design consistency
- Accessible color contrast
- Responsive layout principles

---

## 📄 **License & Privacy**

### **Privacy Commitment**
- Local-first data storage in main branch
- User controls all data
- No tracking or analytics in foundation version
- AI features are opt-in only (pre-prod branch)

### **License**
This project is proprietary. All rights reserved.

---

## 🎊 **Project Status: Multi-Branch Development**

**🌱 Main Branch**: Complete Material Design foundation with beautiful UI
**🎨 Prototype Branch**: Interactive demo with rich, realistic data  
**🚀 Pre-Prod Branch**: Production-ready AI platform with Claude integration

**✨ Choose your development level - from foundation to AI-powered platform.**

---

*Built with ❤️ using Flutter, Material Design 3, and innovative AI integration*

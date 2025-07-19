/// Model representing an onboarding slide with content and configuration
class OnboardingSlide {
  final String id;
  final String title;
  final String content;
  final List<String> keyPoints;
  final String ctaText;
  final String? visualAsset;
  final OnboardingSlideType type;
  final bool hasQuickSetup;
  final Map<String, dynamic>? quickSetupOptions;

  const OnboardingSlide({
    required this.id,
    required this.title,
    required this.content,
    this.keyPoints = const [],
    required this.ctaText,
    this.visualAsset,
    required this.type,
    this.hasQuickSetup = false,
    this.quickSetupOptions,
  });

  factory OnboardingSlide.welcome() {
    return const OnboardingSlide(
      id: 'welcome',
      title: 'Welcome to Your Personal Growth Journey',
      content: 'Spiral Journal helps you understand your emotions and track your personal growth through intelligent journaling. Write freely, discover patterns, and watch your emotional intelligence flourish.',
      ctaText: 'Let\'s explore how it works',
      type: OnboardingSlideType.welcome,
      visualAsset: 'spiral_growth',
    );
  }

  factory OnboardingSlide.privacy() {
    return const OnboardingSlide(
      id: 'privacy',
      title: 'Your Thoughts, Completely Private',
      content: 'Everything you write stays on your device. We use advanced encryption to protect your entries, and you can set up a PIN for extra security. Your personal reflections are yours alone.',
      keyPoints: [
        'Local storage only - no cloud uploads',
        'Military-grade encryption',
        'Optional PIN protection',
        'Complete data ownership',
      ],
      ctaText: 'Privacy first, always',
      type: OnboardingSlideType.privacy,
      visualAsset: 'shield_lock',
    );
  }

  factory OnboardingSlide.aiIntelligence() {
    return const OnboardingSlide(
      id: 'ai_intelligence',
      title: 'Meet Your AI Emotional Intelligence Coach',
      content: 'Our AI analyzes your writing to help you understand emotional patterns and personal growth. It\'s like having a thoughtful friend who remembers everything and helps you see the bigger picture.',
      keyPoints: [
        'Powered by advanced Claude AI',
        'Identifies emotional patterns',
        'Tracks 6 personality cores',
        'Provides personalized insights',
        'Works offline when needed',
      ],
      ctaText: 'Smart insights, just for you',
      type: OnboardingSlideType.aiIntelligence,
      visualAsset: 'brain_heart',
    );
  }

  factory OnboardingSlide.accessibility() {
    return const OnboardingSlide(
      id: 'accessibility',
      title: 'Made for Everyone',
      content: 'Spiral Journal adapts to you. Choose between light and dark themes, adjust text sizes, and use voice features. We believe personal growth should be accessible to everyone.',
      keyPoints: [
        'Full accessibility support',
        'Voice input & output',
        'Customizable text sizes',
        'Light & dark themes',
        'Works with screen readers',
      ],
      ctaText: 'Your way, your journey',
      type: OnboardingSlideType.accessibility,
      visualAsset: 'diverse_hands',
    );
  }

  factory OnboardingSlide.settings() {
    return OnboardingSlide(
      id: 'settings',
      title: 'Personalize Your Experience',
      content: 'Take a moment to set up your preferences. You can always change these later in Settings.',
      ctaText: 'Set up now',
      type: OnboardingSlideType.settings,
      hasQuickSetup: true,
      visualAsset: 'settings_gear',
      quickSetupOptions: {
        'theme': ['Light', 'Dark', 'Auto'],
        'textSize': ['Small', 'Medium', 'Large'],
        'notifications': true,
        'pinSetup': false,
      },
    );
  }

  factory OnboardingSlide.readyToBegin() {
    return const OnboardingSlide(
      id: 'ready',
      title: 'You\'re All Set!',
      content: 'Your personal growth journey starts now. Remember: there\'s no wrong way to journal. Write what feels right, and let the insights come naturally.\n\nEvery entry is a step forward. Every reflection is growth. You\'ve got this.',
      ctaText: 'Start my first entry',
      type: OnboardingSlideType.completion,
      visualAsset: 'open_journal',
    );
  }

  static List<OnboardingSlide> getAllSlides() {
    return [
      OnboardingSlide.welcome(),
      OnboardingSlide.privacy(),
      OnboardingSlide.aiIntelligence(),
      OnboardingSlide.accessibility(),
      OnboardingSlide.settings(),
      OnboardingSlide.readyToBegin(),
    ];
  }
}

enum OnboardingSlideType {
  welcome,
  privacy,
  aiIntelligence,
  accessibility,
  settings,
  completion,
}

/// Configuration for quick setup options
class QuickSetupConfig {
  final String theme;
  final String textSize;
  final bool notifications;
  final bool pinSetup;

  const QuickSetupConfig({
    this.theme = 'Auto',
    this.textSize = 'Medium',
    this.notifications = true,
    this.pinSetup = false,
  });

  QuickSetupConfig copyWith({
    String? theme,
    String? textSize,
    bool? notifications,
    bool? pinSetup,
  }) {
    return QuickSetupConfig(
      theme: theme ?? this.theme,
      textSize: textSize ?? this.textSize,
      notifications: notifications ?? this.notifications,
      pinSetup: pinSetup ?? this.pinSetup,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'textSize': textSize,
      'notifications': notifications,
      'pinSetup': pinSetup,
    };
  }

  factory QuickSetupConfig.fromJson(Map<String, dynamic> json) {
    return QuickSetupConfig(
      theme: json['theme'] ?? 'Auto',
      textSize: json['textSize'] ?? 'Medium',
      notifications: json['notifications'] ?? true,
      pinSetup: json['pinSetup'] ?? false,
    );
  }
}

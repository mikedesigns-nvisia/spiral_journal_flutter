import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/models/core.dart';

class DummyDataService {
  static List<JournalEntry> get journalEntries => [
    JournalEntry(
      id: '1',
      date: DateTime.now().subtract(const Duration(days: 0)),
      content: "Today was absolutely incredible! I finally completed the big project at work that I've been stressed about for weeks. The presentation went better than expected, and my manager was really impressed with the creative approach I took. I feel like all those late nights and weekend work sessions finally paid off. \n\nWhat made it even better was taking a long walk in the park afterward. The autumn leaves are beautiful right now, and I took some time to just breathe and appreciate how far I've come this year. I'm learning to celebrate these victories instead of immediately jumping to the next challenge.",
      mood: ['Happy', 'Energetic'],
      tags: ['work', 'achievement', 'growth'],
    ),
    JournalEntry(
      id: '2',
      date: DateTime.now().subtract(const Duration(days: 1)),
      content: "Had a really thoughtful conversation with my sister today about family expectations and career paths. It's interesting how we can see the same situations so differently based on our personalities and experiences. I'm grateful for her perspective, even when we don't always agree.\n\nI've been thinking a lot about balance lately - between ambition and contentment, between planning and living in the moment. These conversations help me process my thoughts.",
      mood: ['Content', 'Reflective'],
      tags: ['family', 'reflection', 'balance'],
    ),
    JournalEntry(
      id: '3',
      date: DateTime.now().subtract(const Duration(days: 2)),
      content: "Woke up feeling anxious about the presentation tomorrow. My mind keeps racing through all the things that could go wrong. I know I'm prepared, but the imposter syndrome is real.\n\nTried some breathing exercises and went for a run. Physical activity always helps clear my head. Reminding myself that everyone gets nervous and that's normal.",
      mood: ['Unsure', 'Anxious'],
      tags: ['anxiety', 'work', 'self-care'],
    ),
    JournalEntry(
      id: '4',
      date: DateTime.now().subtract(const Duration(days: 5)),
      content: "Spent the weekend working on my art project. There's something so therapeutic about creating something with my hands. No deadlines, no expectations from others - just pure creative flow.\n\nI'm realizing how important it is to have outlets that aren't connected to work or productivity. Just doing something because it brings joy.",
      mood: ['Happy', 'Creative'],
      tags: ['creativity', 'art', 'joy', 'weekend'],
    ),
    JournalEntry(
      id: '5',
      date: DateTime.now().subtract(const Duration(days: 7)),
      content: "Team dinner tonight was exactly what I needed. Sometimes I forget how much I enjoy being around people. We laughed until our stomachs hurt and shared stories I'd never heard before.\n\nI'm grateful for these friendships that have developed at work. It makes even the stressful days more manageable knowing I have this support system.",
      mood: ['Happy', 'Social'],
      tags: ['friends', 'gratitude', 'connection'],
    ),
    JournalEntry(
      id: '6',
      date: DateTime.now().subtract(const Duration(days: 10)),
      content: "Feeling overwhelmed with everything on my plate. Work deadlines, family obligations, personal goals - it all feels like too much right now. I know this feeling will pass, but in the moment it's hard to see clearly.\n\nMaybe I need to reassess my priorities and learn to say no to some things. Self-care isn't selfish.",
      mood: ['Stressed', 'Overwhelmed'],
      tags: ['stress', 'boundaries', 'overwhelm'],
    ),
    JournalEntry(
      id: '7',
      date: DateTime.now().subtract(const Duration(days: 14)),
      content: "Read an amazing book today about mindfulness and presence. The author talked about how we often live in either the past or the future, missing the richness of the present moment.\n\nI want to practice being more present in my daily life. Starting with really tasting my morning coffee instead of scrolling through emails.",
      mood: ['Reflective', 'Inspired'],
      tags: ['mindfulness', 'books', 'growth', 'presence'],
    ),
    JournalEntry(
      id: '8',
      date: DateTime.now().subtract(const Duration(days: 18)),
      content: "Had a difficult conversation with my friend about boundaries. It was uncomfortable but necessary. I'm learning that healthy relationships require honesty, even when it's hard.\n\nI'm proud of myself for speaking up instead of just bottling up my feelings like I used to do.",
      mood: ['Proud', 'Reflective'],
      tags: ['boundaries', 'friendship', 'growth', 'communication'],
    ),
    JournalEntry(
      id: '9',
      date: DateTime.now().subtract(const Duration(days: 21)),
      content: "Lazy Sunday spent reading in bed with my cat purring beside me. Sometimes the best days are the ones with no agenda. Just existing peacefully.\n\nI'm learning to value rest as much as productivity. Both are necessary for a balanced life.",
      mood: ['Content', 'Peaceful'],
      tags: ['rest', 'peace', 'cats', 'balance'],
    ),
    JournalEntry(
      id: '10',
      date: DateTime.now().subtract(const Duration(days: 25)),
      content: "Started learning to play guitar today! My fingers are sore and I can barely play a simple chord, but there's something exciting about being a complete beginner at something.\n\nIt's humbling and energizing at the same time. Reminds me that learning never stops.",
      mood: ['Excited', 'Motivated'],
      tags: ['learning', 'music', 'guitar', 'growth'],
    ),
    JournalEntry(
      id: '11',
      date: DateTime.now().subtract(const Duration(days: 30)),
      content: "Reflecting on this month and all the changes happening in my life. Some days feel like I'm exactly where I need to be, other days I question everything.\n\nI think that uncertainty is part of growth. Learning to be okay with not having all the answers.",
      mood: ['Reflective', 'Uncertain'],
      tags: ['reflection', 'growth', 'uncertainty', 'life'],
    ),
    JournalEntry(
      id: '12',
      date: DateTime.now().subtract(const Duration(days: 35)),
      content: "Volunteer work at the community garden today was so fulfilling. There's something magical about working with the earth and helping grow food for families in need.\n\nIt puts everything in perspective and reminds me of what really matters.",
      mood: ['Fulfilled', 'Grateful'],
      tags: ['volunteering', 'community', 'purpose', 'gratitude'],
    ),
    JournalEntry(
      id: '13',
      date: DateTime.now().subtract(const Duration(days: 42)),
      content: "Bad day at work today. Everything that could go wrong did go wrong. Computer crashed, missed an important email, spilled coffee on my shirt before a meeting.\n\nSometimes life just tests your patience. Tomorrow will be better.",
      mood: ['Frustrated', 'Tired'],
      tags: ['work', 'frustration', 'bad-day'],
    ),
    JournalEntry(
      id: '14',
      date: DateTime.now().subtract(const Duration(days: 48)),
      content: "Meditation retreat this weekend was exactly what my soul needed. Being disconnected from technology and social media for 48 hours felt like a reset button.\n\nI want to incorporate more of this mindful awareness into my daily routine.",
      mood: ['Peaceful', 'Renewed'],
      tags: ['meditation', 'retreat', 'mindfulness', 'renewal'],
    ),
    JournalEntry(
      id: '15',
      date: DateTime.now().subtract(const Duration(days: 55)),
      content: "Celebrated my birthday with close friends and family. Getting older feels different now - less scary and more like an achievement. Each year brings more self-awareness and confidence.\n\nGrateful for all the people who make life meaningful.",
      mood: ['Happy', 'Grateful'],
      tags: ['birthday', 'celebration', 'friends', 'family', 'gratitude'],
    ),
  ];

  static List<Core> get activeCores => [
    Core(
      id: 'optimist',
      name: 'Optimist Core',
      description: 'Maintains positive outlook and sees opportunities in challenges',
      percentage: 78,
      trend: CoreTrend.rising,
      color: 'optimist',
      icon: 'sentiment_very_satisfied',
      lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
      insights: [
        'Your positive mindset has grown 15% this month',
        'Gratitude practices are strengthening this core',
        'Recent achievements boosted your confidence'
      ],
    ),
    Core(
      id: 'reflective',
      name: 'Reflective Core',
      description: 'Processes experiences deeply and learns from introspection',
      percentage: 64,
      trend: CoreTrend.stable,
      color: 'reflective',
      icon: 'self_improvement',
      lastUpdated: DateTime.now().subtract(const Duration(hours: 5)),
      insights: [
        'Consistent journaling strengthens reflection',
        'You process emotions thoughtfully',
        'Seeking balance between thinking and acting'
      ],
    ),
    Core(
      id: 'creative',
      name: 'Creative Core',
      description: 'Expresses imagination and finds innovative solutions',
      percentage: 52,
      trend: CoreTrend.rising,
      color: 'creative',
      icon: 'palette',
      lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
      insights: [
        'Art projects are awakening creativity',
        'Problem-solving at work shows innovation',
        'Exploring new learning opportunities'
      ],
    ),
    Core(
      id: 'social',
      name: 'Social Core',
      description: 'Builds meaningful connections and values relationships',
      percentage: 71,
      trend: CoreTrend.rising,
      color: 'social',
      icon: 'people',
      lastUpdated: DateTime.now().subtract(const Duration(hours: 8)),
      insights: [
        'Stronger workplace friendships developing',
        'Quality time with family increasing',
        'Better communication in relationships'
      ],
    ),
    Core(
      id: 'balance',
      name: 'Balance Core',
      description: 'Seeks harmony between different life aspects',
      percentage: 58,
      trend: CoreTrend.stable,
      color: 'balance',
      icon: 'balance',
      lastUpdated: DateTime.now().subtract(const Duration(hours: 12)),
      insights: [
        'Work-life balance improving slowly',
        'Rest and productivity in better harmony',
        'Learning to set healthy boundaries'
      ],
    ),
    Core(
      id: 'growth',
      name: 'Growth Core',
      description: 'Embraces learning and personal development',
      percentage: 66,
      trend: CoreTrend.rising,
      color: 'growth',
      icon: 'trending_up',
      lastUpdated: DateTime.now().subtract(const Duration(hours: 3)),
      insights: [
        'Guitar lessons showing commitment to learning',
        'Reading habits expanding worldview',
        'Embracing beginner mindset in new areas'
      ],
    ),
  ];

  static Map<String, dynamic> get emotionalInsights => {
    'weeklyMoodAverage': 7.2,
    'moodStability': 85,
    'stressLevel': 'Low',
    'happinessLevel': 'High',
    'emotionalIntelligence': 78,
    'growthAreas': [
      'Stress management during high-pressure situations',
      'Expressing emotions more openly in relationships',
      'Building resilience for setbacks'
    ],
    'strengths': [
      'Strong self-awareness and reflection skills',
      'Positive outlook and gratitude practice',
      'Healthy coping mechanisms and self-care'
    ],
    'moodPatterns': {
      'Monday': 6.5,
      'Tuesday': 7.1,
      'Wednesday': 7.8,
      'Thursday': 7.2,
      'Friday': 8.1,
      'Saturday': 8.5,
      'Sunday': 7.9,
    },
    'monthlyTrends': [
      {'month': 'September', 'happiness': 7.8, 'stress': 4.2, 'energy': 7.1},
      {'month': 'October', 'happiness': 8.1, 'stress': 3.8, 'energy': 7.5},
      {'month': 'November', 'happiness': 7.9, 'stress': 4.1, 'energy': 7.3},
      {'month': 'December', 'happiness': 8.3, 'stress': 3.5, 'energy': 7.8},
    ],
  };

  static List<String> get availableMoods => [
    'Happy', 'Content', 'Unsure', 'Sad', 'Energetic', 
    'Anxious', 'Excited', 'Frustrated', 'Peaceful', 
    'Grateful', 'Inspired', 'Overwhelmed', 'Proud',
    'Reflective', 'Creative', 'Social', 'Tired'
  ];

  static List<String> get journalPrompts => [
    "What made you smile today?",
    "Describe a moment when you felt truly present.",
    "What's something you're grateful for right now?",
    "How did you grow or learn something new today?",
    "What challenged you today and how did you handle it?",
    "Describe a person who positively impacted your day.",
    "What's one thing you want to remember about today?",
    "How are you feeling about your current life direction?",
    "What's bringing you energy right now?",
    "Describe a recent accomplishment you're proud of.",
  ];

  static Map<String, dynamic> get userStats => {
    'totalEntries': journalEntries.length,
    'entriesThisMonth': journalEntries.where((entry) => 
      entry.date.isAfter(DateTime.now().subtract(const Duration(days: 30)))
    ).length,
    'currentStreak': 5,
    'longestStreak': 12,
    'averageWordsPerEntry': 187,
    'mostFrequentMood': 'Happy',
    'journalingStartDate': DateTime.now().subtract(const Duration(days: 90)),
    'favoritePrompts': [
      "What made you smile today?",
      "Describe a moment when you felt truly present.",
      "What's something you're grateful for right now?"
    ],
  };
}

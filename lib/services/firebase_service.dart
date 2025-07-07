import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../models/journal_entry.dart';
import '../models/core.dart';
import '../models/ai_analysis.dart';

/// Firebase service for real backend data operations
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  
  CollectionReference _userJournalEntries(String userId) => 
      _usersCollection.doc(userId).collection('journal_entries');
      
  CollectionReference _userCores(String userId) => 
      _usersCollection.doc(userId).collection('cores');
      
  CollectionReference _userAnalyses(String userId) => 
      _usersCollection.doc(userId).collection('ai_analyses');

  // Current user getter
  String? get currentUserId => _auth.currentUser?.uid;
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;

  /// Authentication Methods
  
  /// Sign in anonymously for demo/trial usage
  Future<UserCredential> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      await _createUserProfile(credential.user!);
      await _analytics.logLogin(loginMethod: 'anonymous');
      return credential;
    } catch (e) {
      throw AuthException('Failed to sign in anonymously: $e');
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _analytics.logLogin(loginMethod: 'email');
      return credential;
    } catch (e) {
      throw AuthException('Failed to sign in: $e');
    }
  }

  /// Create account with email and password
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (displayName != null) {
        await credential.user!.updateDisplayName(displayName);
      }
      
      await _createUserProfile(credential.user!);
      await _analytics.logSignUp(signUpMethod: 'email');
      return credential;
    } catch (e) {
      throw AuthException('Failed to create account: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Create initial user profile and default cores
  Future<void> _createUserProfile(User user) async {
    final userDoc = _usersCollection.doc(user.uid);
    
    // Check if user profile already exists
    final docSnapshot = await userDoc.get();
    if (docSnapshot.exists) return;

    // Create user profile
    await userDoc.set({
      'uid': user.uid,
      'email': user.email,
      'display_name': user.displayName,
      'created_at': FieldValue.serverTimestamp(),
      'last_active': FieldValue.serverTimestamp(),
      'settings': {
        'ai_analysis_enabled': true,
        'theme_mode': 'system',
        'notifications_enabled': true,
      },
    });

    // Create default cores
    await _initializeDefaultCores(user.uid);
  }

  /// Initialize default personality cores for new users
  Future<void> _initializeDefaultCores(String userId) async {
    final defaultCores = {
      'optimism': EmotionalCore(
        id: 'optimism',
        name: 'Optimism',
        description: 'Your positive outlook and hope for the future',
        percentage: 65.0,
        trend: 'stable',
        color: '0xFFFF9800',
        iconPath: 'assets/icons/optimism.png',
        insight: 'Building positive outlook',
        relatedCores: ['resilience', 'growth_mindset'],
      ),
      'resilience': EmotionalCore(
        id: 'resilience',
        name: 'Resilience',
        description: 'Your ability to bounce back from challenges',
        percentage: 60.0,
        trend: 'stable',
        color: '0xFF4CAF50',
        iconPath: 'assets/icons/resilience.png',
        insight: 'Developing coping strategies',
        relatedCores: ['optimism', 'self_awareness'],
      ),
      'self_awareness': EmotionalCore(
        id: 'self_awareness',
        name: 'Self-Awareness',
        description: 'Your understanding of your thoughts and emotions',
        percentage: 70.0,
        trend: 'stable',
        color: '0xFF2196F3',
        iconPath: 'assets/icons/self_awareness.png',
        insight: 'Growing emotional intelligence',
        relatedCores: ['resilience', 'creativity'],
      ),
      'creativity': EmotionalCore(
        id: 'creativity',
        name: 'Creativity',
        description: 'Your innovative thinking and creative expression',
        percentage: 55.0,
        trend: 'stable',
        color: '0xFF9C27B0',
        iconPath: 'assets/icons/creativity.png',
        insight: 'Exploring creative potential',
        relatedCores: ['self_awareness', 'social_connection'],
      ),
      'social_connection': EmotionalCore(
        id: 'social_connection',
        name: 'Social Connection',
        description: 'Your ability to connect and relate to others',
        percentage: 58.0,
        trend: 'stable',
        color: '0xFFE91E63',
        iconPath: 'assets/icons/social_connection.png',
        insight: 'Building meaningful relationships',
        relatedCores: ['creativity', 'growth_mindset'],
      ),
      'growth_mindset': EmotionalCore(
        id: 'growth_mindset',
        name: 'Growth Mindset',
        description: 'Your openness to learning and personal development',
        percentage: 62.0,
        trend: 'stable',
        color: '0xFF00BCD4',
        iconPath: 'assets/icons/growth_mindset.png',
        insight: 'Embracing continuous learning',
        relatedCores: ['optimism', 'social_connection'],
      ),
    };

    final batch = _firestore.batch();
    final coresCollection = _userCores(userId);

    for (final core in defaultCores.values) {
      batch.set(coresCollection.doc(core.id), core.toJson());
    }

    await batch.commit();
  }

  /// Journal Entry Operations

  /// Save a new journal entry
  Future<void> saveJournalEntry(JournalEntry entry) async {
    if (currentUserId == null) throw AuthException('User not authenticated');

    try {
      await _userJournalEntries(currentUserId!)
          .doc(entry.id)
          .set(entry.toJson());
          
          await _analytics.logEvent(
        name: 'journal_entry_created',
        parameters: {
          'word_count': entry.content.length,
          'has_moods': entry.moods.isNotEmpty,
          'day_of_week': entry.dayOfWeek,
        },
      );
    } catch (e) {
      throw FirebaseServiceException('Failed to save journal entry: $e');
    }
  }

  /// Get all journal entries for current user
  Future<List<JournalEntry>> getJournalEntries({int? limit}) async {
    if (currentUserId == null) throw AuthException('User not authenticated');

    try {
      Query query = _userJournalEntries(currentUserId!)
          .orderBy('date', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => JournalEntry.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirebaseServiceException('Failed to get journal entries: $e');
    }
  }

  /// Get journal entries stream for real-time updates
  Stream<List<JournalEntry>> getJournalEntriesStream() {
    if (currentUserId == null) throw AuthException('User not authenticated');

    return _userJournalEntries(currentUserId!)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JournalEntry.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Core Operations

  /// Get user's cores
  Future<Map<String, EmotionalCore>> getCores() async {
    if (currentUserId == null) throw AuthException('User not authenticated');

    try {
      final snapshot = await _userCores(currentUserId!).get();
      final Map<String, EmotionalCore> cores = {};

      for (final doc in snapshot.docs) {
        final core = EmotionalCore.fromJson(doc.data() as Map<String, dynamic>);
        cores[core.id] = core;
      }

      return cores;
    } catch (e) {
      throw FirebaseServiceException('Failed to get cores: $e');
    }
  }

  /// Update cores based on AI analysis
  Future<void> updateCores(Map<String, EmotionalCore> updatedCores) async {
    if (currentUserId == null) throw AuthException('User not authenticated');

    try {
      final batch = _firestore.batch();
      final coresCollection = _userCores(currentUserId!);

      for (final core in updatedCores.values) {
        batch.set(coresCollection.doc(core.id), core.toJson());
      }

      await batch.commit();
    } catch (e) {
      throw FirebaseServiceException('Failed to update cores: $e');
    }
  }

  /// Get cores stream for real-time updates
  Stream<Map<String, EmotionalCore>> getCoresStream() {
    if (currentUserId == null) throw AuthException('User not authenticated');

    return _userCores(currentUserId!)
        .snapshots()
        .map((snapshot) {
          final Map<String, EmotionalCore> cores = {};
          for (final doc in snapshot.docs) {
            final core = EmotionalCore.fromJson(doc.data() as Map<String, dynamic>);
            cores[core.id] = core;
          }
          return cores;
        });
  }

  /// AI Analysis Operations

  /// Save AI analysis result
  Future<void> saveAIAnalysis(AIAnalysis analysis) async {
    if (currentUserId == null) throw AuthException('User not authenticated');

    try {
      await _userAnalyses(currentUserId!)
          .doc(analysis.id)
          .set(analysis.toJson());
          
      await _analytics.logEvent(
        name: 'ai_analysis_completed',
        parameters: {
          'confidence': analysis.confidence,
          'analysis_type': 'full_pipeline',
        },
      );
    } catch (e) {
      throw FirebaseServiceException('Failed to save AI analysis: $e');
    }
  }

  /// Get AI analysis for a specific entry
  Future<AIAnalysis?> getAIAnalysis(String entryId) async {
    if (currentUserId == null) throw AuthException('User not authenticated');

    try {
      final snapshot = await _userAnalyses(currentUserId!)
          .where('entry_id', isEqualTo: entryId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return AIAnalysis.fromJson(snapshot.docs.first.data() as Map<String, dynamic>);
    } catch (e) {
      throw FirebaseServiceException('Failed to get AI analysis: $e');
    }
  }

  /// Get recent AI analyses for pattern recognition
  Future<List<AIAnalysis>> getRecentAnalyses({int limit = 10}) async {
    if (currentUserId == null) throw AuthException('User not authenticated');

    try {
      final snapshot = await _userAnalyses(currentUserId!)
          .orderBy('analyzed_at', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AIAnalysis.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirebaseServiceException('Failed to get recent analyses: $e');
    }
  }

  /// Analytics and Insights

  /// Log user activity for analytics
  Future<void> logUserActivity(String activityType) async {
    await _analytics.logEvent(
      name: 'user_activity',
      parameters: {'activity_type': activityType},
    );
  }

  /// Update user's last active timestamp
  Future<void> updateLastActive() async {
    if (currentUserId == null) return;

    await _usersCollection.doc(currentUserId!).update({
      'last_active': FieldValue.serverTimestamp(),
    });
  }
}

/// Exception thrown when Firebase operations fail
class FirebaseServiceException implements Exception {
  final String message;
  
  FirebaseServiceException(this.message);
  
  @override
  String toString() => 'FirebaseServiceException: $message';
}

/// Exception thrown when authentication fails
class AuthException implements Exception {
  final String message;
  
  AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}

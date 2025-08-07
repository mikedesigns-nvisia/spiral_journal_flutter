// Dart imports
import 'dart:async';
import 'dart:io';

// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports
import 'package:spiral_journal/core/app_constants.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/design_system/heading_system.dart';
import 'package:spiral_journal/design_system/responsive_layout.dart';
import 'package:spiral_journal/models/emotional_mirror_data.dart';
import 'package:spiral_journal/models/emotional_state.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/providers/core_provider_refactored.dart';
import 'package:spiral_journal/providers/emotional_mirror_provider.dart';
import 'package:spiral_journal/providers/journal_provider.dart';
import 'package:spiral_journal/services/journal_service.dart';
import 'package:spiral_journal/services/navigation_service.dart';
import 'package:spiral_journal/services/profile_service.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/utils/ios_theme_enforcer.dart';
import 'package:spiral_journal/widgets/journal_input.dart';
import 'package:spiral_journal/widgets/mood_selector.dart';
import 'package:spiral_journal/widgets/primary_emotional_state_widget.dart';
import 'package:spiral_journal/widgets/your_cores_card.dart';
import 'package:spiral_journal/widgets/emotional_journey_visualization.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _journalController = TextEditingController();
  final List<String> _selectedMoods = [];
  
  String? _draftContent;
  String _userName = 'there'; // Default fallback name
  bool _hasProcessedEntryToday = false; // Track if user has already saved an entry today
  
  // Mirror snapshot state
  bool _showingSnapshot = false;
  JournalEntry? _savedEntry;
  
  // Post-analysis state tracking
  bool _isAiEnabled = true; // Will be loaded from settings

  @override
  void initState() {
    super.initState();
    _loadDraftContent();
    _loadUserName();
    _loadAiSettings();
    _startPeriodicAnalysisCheck();
    
    // Initial state refresh to ensure UI is consistent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        refreshJournalScreenState();
      }
    });
  }

  /// Start periodic check for completed analysis and state refresh
  void _startPeriodicAnalysisCheck() {
    // Check every 5 minutes for completed batch analysis and refresh state
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        refreshJournalScreenState();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  // Add this method to show snapshot after save:
  void _showSnapshot(JournalEntry entry) {
    debugPrint('🎯 Showing snapshot for entry: ${entry.id}');
    setState(() {
      _showingSnapshot = true;
      _savedEntry = entry;
      _hasProcessedEntryToday = false; // Reset this so snapshot shows instead of emotional state widget
    });
  }

  // Add this method to reset to input mode:
  void _resetToInputMode() {
    setState(() {
      _showingSnapshot = false;
      _savedEntry = null;
      _journalController.clear();
      _selectedMoods.clear();
    });
  }

  Future<void> _loadDraftContent() async {
    // Load any existing draft content from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftContent = prefs.getString('journal_draft_content');
      final draftMoods = prefs.getStringList('journal_draft_moods') ?? [];
      
      // Check if user has already processed an entry today
      await _checkHasProcessedEntryToday();
      
      if (draftContent != null && draftContent.isNotEmpty) {
        if (mounted) {
          setState(() {
            _draftContent = draftContent;
            _selectedMoods.clear();
            _selectedMoods.addAll(draftMoods);
          });
        }
        
        // Only show recovery dialog if user hasn't already saved an entry today
        // If they have, the draft is likely from the same content they already saved
        if (mounted && !_hasProcessedEntryToday) {
          _showDraftRecoveryDialog(draftContent);
        } else if (_hasProcessedEntryToday) {
          // User already saved today, clear the draft since it's likely already in history
          await _clearDraftContent();
          debugPrint('Cleared draft content - user already has entry in history today');
        }
      }
    } catch (e) {
      debugPrint('Error loading draft content: $e');
    }
  }

  /// Check if user has already processed (saved) an entry today
  Future<void> _checkHasProcessedEntryToday() async {
    try {
      final journalService = JournalService();
      final todaysEntry = await journalService.getTodaysEntry();
      
      if (mounted) {
        setState(() {
          _hasProcessedEntryToday = todaysEntry != null;
        });
      }
    } catch (e) {
      debugPrint('Error checking today\'s processed entry: $e');
    }
  }

  Future<void> _saveDraftContent(String content) async {
    // Save draft content for crash recovery
    try {
      final prefs = await SharedPreferences.getInstance();
      if (content.trim().isNotEmpty) {
        await prefs.setString('journal_draft_content', content);
        await prefs.setStringList('journal_draft_moods', _selectedMoods);
      } else {
        await prefs.remove('journal_draft_content');
        await prefs.remove('journal_draft_moods');
      }
      
      if (mounted) {
        setState(() {
          _draftContent = content;
        });
      }
    } catch (e) {
      debugPrint('Error saving draft content: $e');
    }
  }

  Future<void> _clearDraftContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('journal_draft_content');
      await prefs.remove('journal_draft_moods');
      
      if (mounted) {
        setState(() {
          _draftContent = null;
        });
      }
    } catch (e) {
      debugPrint('Error clearing draft content: $e');
    }
  }

  Future<void> _loadUserName() async {
    try {
      final profileService = ProfileService();
      final displayName = await profileService.getDisplayName();
      
      if (mounted) {
        setState(() {
          _userName = displayName;
        });
      }
    } catch (e) {
      debugPrint('Error loading user name: $e');
      // Keep default fallback name 'there'
    }
  }

  Future<void> _loadAiSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final aiEnabled = prefs.getBool('ai_analysis_enabled') ?? true;
      
      if (mounted) {
        setState(() {
          _isAiEnabled = aiEnabled;
        });
      }
    } catch (e) {
      debugPrint('Error loading AI settings: $e');
    }
  }


  /// Refresh complete journal screen state after entry processing
  Future<void> refreshJournalScreenState() async {
    debugPrint('🔄 Refreshing complete journal screen state...');
    
    // Check if user has processed an entry today
    await _checkHasProcessedEntryToday();
    
    
    // If user has already processed an entry today, clear any lingering drafts
    if (_hasProcessedEntryToday && _draftContent != null) {
      await _clearDraftContent();
      debugPrint('✅ Cleared lingering draft - user already has entry in history');
    }
  }

  /// Handle pull-to-refresh gesture
  Future<void> _handleRefresh() async {
    debugPrint('🔄 Pull-to-refresh triggered');
    
    try {
      // Show feedback to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Refreshing journal state...'),
            backgroundColor: DesignTokens.getPrimaryColor(context),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      
      // Refresh journal provider data
      if (mounted) {
        final journalProvider = Provider.of<JournalProvider>(context, listen: false);
        final coreProvider = Provider.of<CoreProvider>(context, listen: false);
        
        await journalProvider.refresh();
        await coreProvider.refresh();
      }
      
      // Refresh complete journal screen state
      await refreshJournalScreenState();
      
      debugPrint('✅ Pull-to-refresh completed successfully');
      
    } catch (e) {
      debugPrint('❌ Pull-to-refresh error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refresh failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<JournalEntry?> _getTodaysAnalyzedEntry(JournalProvider journalProvider) async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      // Get all entries and find today's analyzed entry
      final entries = journalProvider.entries;
      for (final entry in entries) {
        if (entry.createdAt.isAfter(todayStart) && 
            entry.createdAt.isBefore(todayEnd)) {
          return entry;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting today\'s analyzed entry: $e');
      return null;
    }
  }

  /// Synchronous version to get today's analyzed entry for UI building
  JournalEntry? _getTodaysAnalyzedEntrySync(JournalProvider journalProvider) {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      // Get all entries and find today's analyzed entry
      final entries = journalProvider.entries;
      for (final entry in entries) {
        if (entry.createdAt.isAfter(todayStart) && 
            entry.createdAt.isBefore(todayEnd)) {
          return entry;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting today\'s analyzed entry sync: $e');
      return null;
    }
  }


  void _showDraftRecoveryDialog(String draftContent) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Recover Draft'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('We found an unsaved draft from your previous session:'),
              const SizedBox(height: AppConstants.spacing12),
              Container(
                padding: const EdgeInsets.all(AppConstants.spacing12),
                decoration: BoxDecoration(
                  color: DesignTokens.getColorWithOpacity(DesignTokens.getBackgroundTertiary(context), 0.5),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  border: Border.all(
                    color: DesignTokens.getColorWithOpacity(DesignTokens.getPrimaryColor(context), 0.3),
                  ),
                ),
                child: Text(
                  draftContent.length > 100 
                      ? '${draftContent.substring(0, 100)}...' 
                      : draftContent,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearDraftContent();
                Navigator.of(context).pop();
              },
              child: const Text('Discard'),
            ),
            ElevatedButton(
              onPressed: () {
                _journalController.text = draftContent;
                Navigator.of(context).pop();
              },
              child: const Text('Recover'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _saveEntry() async {
    if (_journalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please write something before saving!'),
          backgroundColor: DesignTokens.errorColor,
        ),
      );
      return;
    }

    if (_selectedMoods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one mood!'),
          backgroundColor: DesignTokens.errorColor,
        ),
      );
      return;
    }

    // Phase 5: Check 24-hour entry limit
    final journalService = JournalService();
    final canCreateEntry = await journalService.canCreateEntryToday();
    
    if (!canCreateEntry) {
      final todaysEntry = await journalService.getTodaysEntry();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You\'ve already created an entry today! Come back tomorrow to continue your journey.',
          ),
          backgroundColor: DesignTokens.warningColor,
          duration: const Duration(seconds: 4),
          action: todaysEntry != null 
              ? SnackBarAction(
                  label: 'View Today\'s Entry',
                  onPressed: () {
                    // Navigate to journal history or show today's entry
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Today\'s entry: "${todaysEntry.content.length > 50 ? '${todaysEntry.content.substring(0, 50)}...' : todaysEntry.content}"'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                )
              : null,
        ),
      );
      return;
    }

    if (!mounted) return;
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final coreProvider = Provider.of<CoreProvider>(context, listen: false);

    // Show initial saving message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Saving entry... ✍️'),
        backgroundColor: DesignTokens.getPrimaryColor(context),
        duration: const Duration(seconds: 1),
      ),
    );

    final success = await journalProvider.createEntry(
      content: _journalController.text.trim(),
      moods: _selectedMoods,
    );

    if (mounted) {
      if (success) {
        // Clear draft content after successful save
        await _clearDraftContent();

        // Mark that user has processed an entry today and show immediate emotional state widget
        setState(() {
          _hasProcessedEntryToday = true;
        });

        // Refresh cores after saving entry
        await coreProvider.refresh();

        // Refresh journal entries so they appear immediately in history
        await journalProvider.refresh();

        // Get the saved entry and navigate to emotional mirror
        final todaysEntry = await journalService.getTodaysEntry();
        debugPrint('📝 Retrieved today\'s entry after save: ${todaysEntry?.id}');
        
        if (todaysEntry != null) {
          // Show the emotional mirror widget in place on journal screen
          debugPrint('🎯 Showing emotional mirror widget for entry: ${todaysEntry.id}');
          
          // Refresh the emotional mirror provider to include the new entry
          if (mounted) {
            final mirrorProvider = Provider.of<EmotionalMirrorProvider>(context, listen: false);
            await mirrorProvider.refresh();
          }
          
          // Set state to show the emotional mirror widget
          setState(() {
            _showingSnapshot = false; // Don't show the simple snapshot
            _savedEntry = todaysEntry;
            _hasProcessedEntryToday = true; // This will trigger the mirror display
          });
        } else {
          debugPrint('❌ No today\'s entry found after save');
        }

        // Show success message with batch analysis info
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Entry saved successfully! 🎉'),
                  const SizedBox(height: AppConstants.spacing4),
                  Text(
                    'Your Emotional Mirror is now ready below',
                    style: HeadingSystem.getBodySmall(context).copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.accentGreen,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save entry: ${journalProvider.error ?? 'Unknown error'}'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
      }
    }
  }



  


  Widget _buildEnhancedEmotionalState(EmotionalMirrorProvider mirrorProvider, JournalEntry entry) {
    // Get primary and secondary emotional states from the provider (same as emotional mirror)
    final primaryState = mirrorProvider.getPrimaryEmotionalState(context);
    final secondaryState = mirrorProvider.getSecondaryEmotionalState(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.getPrimaryColor(context).withValues(alpha: 0.05),
            DesignTokens.accentBlue.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Emotional State Widget (same as emotional mirror)
          PrimaryEmotionalStateWidget(
            primaryState: primaryState,
            secondaryState: secondaryState,
            showTabs: secondaryState != null,
            showTimestamp: true,
            showConfidence: false,
            focusable: true,
            showAnimation: true,
            onTap: primaryState != null ? () => _showJournalEmotionalStateDetails(primaryState, secondaryState, mirrorProvider) : null,
          ),
          
          // Real emotional insights from today's analysis
          if (mirrorProvider.mirrorData?.insights != null && mirrorProvider.mirrorData!.insights.isNotEmpty) ...[
            SizedBox(height: DesignTokens.spaceL),
            _buildTodaysInsights(mirrorProvider),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTodaysInsights(EmotionalMirrorProvider mirrorProvider) {
    final insights = mirrorProvider.mirrorData!.insights.take(2).toList();
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: DesignTokens.spaceL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.accentYellow.withValues(alpha: 0.1),
            DesignTokens.accentYellow.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: DesignTokens.accentYellow.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.spaceM),
            decoration: BoxDecoration(
              color: DesignTokens.accentYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(DesignTokens.radiusL),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(DesignTokens.spaceS),
                  decoration: BoxDecoration(
                    color: DesignTokens.accentYellow.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    color: DesignTokens.accentYellow,
                    size: DesignTokens.iconSizeS,
                  ),
                ),
                SizedBox(width: DesignTokens.spaceM),
                Text(
                  'Today\'s Insights',
                  style: HeadingSystem.getTitleSmall(context).copyWith(
                    fontWeight: FontWeight.bold,
                    color: DesignTokens.getTextPrimary(context),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(DesignTokens.spaceM),
            child: Column(
              children: insights.map((insight) => Container(
                margin: EdgeInsets.only(bottom: DesignTokens.spaceM),
                padding: EdgeInsets.all(DesignTokens.spaceM),
                decoration: BoxDecoration(
                  color: DesignTokens.getBackgroundPrimary(context).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        color: DesignTokens.accentYellow,
                        size: DesignTokens.iconSizeS,
                      ),
                    ),
                    SizedBox(width: DesignTokens.spaceM),
                    Expanded(
                      child: Text(
                        insight,
                        style: HeadingSystem.getBodySmall(context).copyWith(
                          height: 1.5,
                          color: DesignTokens.getTextPrimary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showJournalEmotionalStateDetails(EmotionalState primaryState, EmotionalState? secondaryState, EmotionalMirrorProvider mirrorProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: DesignTokens.getBackgroundPrimary(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusXL)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(DesignTokens.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(bottom: DesignTokens.spaceL),
                    decoration: BoxDecoration(
                      color: DesignTokens.getBackgroundTertiary(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                // Title
                Text(
                  'Today\'s Emotional Analysis',
                  style: HeadingSystem.getHeadlineMedium(context),
                ),
                SizedBox(height: DesignTokens.spaceXL),
                
                // Primary emotion details
                _buildJournalEmotionDetailCard('Primary Emotion', primaryState, Icons.star, DesignTokens.getPrimaryColor(context)),
                
                if (secondaryState != null) ...[
                  SizedBox(height: DesignTokens.spaceL),
                  _buildJournalEmotionDetailCard('Secondary Emotion', secondaryState, Icons.star_half, DesignTokens.accentBlue),
                ],
                
                // Quick access to full emotional mirror
                SizedBox(height: DesignTokens.spaceXL),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to emotional mirror screen
                      NavigationService.instance.switchToTab(2); // Mirror tab
                    },
                    icon: Icon(Icons.psychology_rounded),
                    label: Text('View Full Emotional Mirror'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.getPrimaryColor(context),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceL, vertical: DesignTokens.spaceM),
                    ),
                  ),
                ),
                
                SizedBox(height: DesignTokens.spaceXL),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildJournalEmotionDetailCard(String title, EmotionalState state, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: DesignTokens.iconSizeM),
              SizedBox(width: DesignTokens.spaceM),
              Text(
                title,
                style: HeadingSystem.getTitleMedium(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceM),
          
          // Emotion name and intensity
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.displayName,
                      style: HeadingSystem.getHeadlineMedium(context),
                    ),
                    SizedBox(height: DesignTokens.spaceXS),
                    Text(
                      state.description,
                      style: HeadingSystem.getBodyMedium(context).copyWith(
                        color: DesignTokens.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceM),
                decoration: BoxDecoration(
                  color: state.accessibleColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${((state.intensity > 1.0 ? state.intensity / 10.0 : state.intensity) * 100).round()}%',
                  style: HeadingSystem.getTitleMedium(context).copyWith(
                    color: state.accessibleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Get color for mood chip
  Color _getMoodColor(String mood) {
    final moodLower = mood.toLowerCase();
    if (moodLower.contains('happy') || moodLower.contains('joy')) return AppTheme.accentGreen;
    if (moodLower.contains('grateful') || moodLower.contains('love')) return AppTheme.accentRed;
    if (moodLower.contains('content') || moodLower.contains('peaceful')) return Colors.grey;
    if (moodLower.contains('excited') || moodLower.contains('confident')) return AppTheme.primaryOrange;
    if (moodLower.contains('sad') || moodLower.contains('disappointed')) return Colors.blue;
    if (moodLower.contains('angry') || moodLower.contains('frustrated')) return AppTheme.accentRed;
    if (moodLower.contains('anxious') || moodLower.contains('worried')) return Colors.purple;
    if (moodLower.contains('stressed') || moodLower.contains('overwhelmed')) return Colors.orange;
    return AppTheme.primaryOrange;
  }

  /// Create MoodOverview from journal entry for emotional state visualization
  MoodOverview _createMoodOverviewFromEntry(JournalEntry entry) {
    // Calculate mood balance based on mood sentiment
    double moodBalance = _calculateMoodBalance(entry.moods);
    
    // Calculate emotional variety (normalized by max expected moods)
    double emotionalVariety = (entry.moods.length / 5.0).clamp(0.0, 1.0);
    
    // Generate description based on entry
    String description = 'Your emotional state reflects ${entry.moods.take(2).join(" and ")}. '
        'Thank you for taking time to reflect and journal today.';
    
    return MoodOverview(
      dominantMoods: entry.moods.take(4).toList(),
      moodBalance: moodBalance,
      emotionalVariety: emotionalVariety,
      description: description,
    );
  }
  
  /// Calculate mood balance from moods list
  double _calculateMoodBalance(List<String> moods) {
    final positiveEmotions = ['happy', 'joyful', 'excited', 'grateful', 'content', 'peaceful', 'love', 'joy', 'optimistic', 'confident'];
    final negativeEmotions = ['sad', 'angry', 'frustrated', 'anxious', 'worried', 'fear', 'disappointment', 'stress', 'overwhelmed'];
    
    double balance = 0.0;
    for (final mood in moods) {
      if (positiveEmotions.contains(mood.toLowerCase())) {
        balance += 0.3;
      } else if (negativeEmotions.contains(mood.toLowerCase())) {
        balance -= 0.3;
      }
    }
    
    return balance.clamp(-1.0, 1.0);
  }


  Widget _buildNormalJournalInput() {
    final now = DateTime.now();
    final dateFormatter = DateFormat('EEEE, MMMM d');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Simplified header - more space efficient
        Row(
          children: [
            // Compact app branding
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignTokens.getColorWithOpacity(
                  DesignTokens.getPrimaryColor(context), 
                  0.1
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                color: DesignTokens.getPrimaryColor(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spiral Journal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.getTextPrimary(context),
                    ),
                  ),
                  Text(
                    dateFormatter.format(now),
                    style: TextStyle(
                      fontSize: 13,
                      color: DesignTokens.getTextTertiary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Conditional greeting and analysis status - only show when no analysis is complete
        Consumer<JournalProvider>(
          builder: (context, journalProvider, child) {
            final todaysAnalyzedEntry = _getTodaysAnalyzedEntrySync(journalProvider);
            final hasAnalyzedEntry = todaysAnalyzedEntry != null;
            
            if (hasAnalyzedEntry) {
              // Skip greeting when analysis is complete - minimal spacing
              return const SizedBox(height: 8);
            } else {
              // Compact greeting and analysis status
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Streamlined greeting
                  Text(
                    'Hi $_userName, how are you feeling today?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.getTextPrimary(context),
                      height: 1.3,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              );
            }
          },
        ),
        
        // Conditional: Show Mind Reflection if analyzed, snapshot if pending, or input tools if no entry
        Consumer<JournalProvider>(
          builder: (context, journalProvider, child) {
            // Check if today's entry has been analyzed by AI
            final todaysAnalyzedEntry = _getTodaysAnalyzedEntrySync(journalProvider);
            
            if (todaysAnalyzedEntry != null) {
              // Show full emotional mirror visualization when entry is processed
              return Consumer<EmotionalMirrorProvider>(
                builder: (context, mirrorProvider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Row(
                        children: [
                          Icon(
                            Icons.psychology_rounded,
                            color: DesignTokens.getPrimaryColor(context),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Your Emotional Mirror',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: DesignTokens.getTextPrimary(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Enhanced Emotional State using real analysis data
                      _buildEnhancedEmotionalState(mirrorProvider, todaysAnalyzedEntry),
                      
                      const SizedBox(height: 20),
                      
                      // Entry summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: DesignTokens.getCardGradient(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today\'s Reflection',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: DesignTokens.getTextPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              todaysAnalyzedEntry.preview,
                              style: TextStyle(
                                fontSize: 14,
                                color: DesignTokens.getTextSecondary(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: todaysAnalyzedEntry.moods.map((mood) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getMoodColor(mood).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _getMoodColor(mood)),
                                ),
                                child: Text(
                                  mood,
                                  style: TextStyle(
                                    color: _getMoodColor(mood),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Action to write tomorrow
                      Center(
                        child: TextButton.icon(
                          onPressed: _resetToInputMode,
                          icon: Icon(Icons.edit_note_rounded),
                          label: Text('Write Tomorrow\'s Entry'),
                          style: TextButton.styleFrom(
                            foregroundColor: DesignTokens.getPrimaryColor(context),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            } else if (_showingSnapshot && _savedEntry != null) {
              // Show snapshot while analysis is pending
              return Column(
                children: [
                  // Emotional Journey Visualization
                  EmotionalJourneyVisualization(
                    recentEntries: _savedEntry != null ? [_savedEntry!] : [],
                    dominantMoods: _savedEntry?.moods ?? [],
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _resetToInputMode,
                    child: const Text('Write Another Entry Tomorrow'),
                  ),
                ],
              );
            } else {
              // Show input tools when no entry exists today - optimized spacing
              return Column(
                children: [
                  // Mood Selector
                  MoodSelector(
                    selectedMoods: _selectedMoods,
                    onMoodChanged: (moods) {
                      if (mounted) {
                        setState(() {
                          _selectedMoods.clear();
                          _selectedMoods.addAll(moods);
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Journal Input
                  JournalInput(
                    controller: _journalController,
                    onChanged: (text) {
                      // Handle text changes if needed
                    },
                    onSave: _saveEntry,
                    isSaving: journalProvider.isLoading,
                    onAutoSave: _saveDraftContent,
                    draftContent: _draftContent,
                  ),
                ],
              );
            }
          },
        ),
        
        const SizedBox(height: 20),
        
        // Your Cores Card - always show
        const YourCoresCard(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    // Use iOS-specific keyboard dismissal and safe area handling
    Widget body = AdaptiveScaffold(
        backgroundColor: DesignTokens.getBackgroundPrimary(context),
        padding: EdgeInsets.zero, // Remove default padding to avoid double padding
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: DesignTokens.getPrimaryColor(context),
          backgroundColor: DesignTokens.getBackgroundPrimary(context),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120), // Optimized padding - more space for content
            physics: const AlwaysScrollableScrollPhysics(), // Ensure pull-to-refresh works even when content doesn't fill screen
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNormalJournalInput(),
              ],
            ),
          ),
        ),
    );
    
    // Apply iOS-specific safe area and keyboard handling
    return iOSThemeEnforcer.withSafeArea(
      child: iOSThemeEnforcer.withKeyboardDismissal(
        context: context,
        child: body,
      ),
      bottom: Platform.isIOS, // Only apply bottom safe area on iOS
    );
  }

}

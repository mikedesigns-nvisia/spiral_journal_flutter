import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/design_system/component_library.dart';
import 'package:spiral_journal/design_system/responsive_layout.dart';
import 'package:spiral_journal/widgets/mood_selector.dart';
import 'package:spiral_journal/widgets/journal_input.dart';
import 'package:spiral_journal/widgets/mind_reflection_card.dart';
import 'package:spiral_journal/widgets/your_cores_card.dart';
import 'package:spiral_journal/widgets/compact_analysis_counter.dart';
import 'package:spiral_journal/providers/journal_provider.dart';
import 'package:spiral_journal/providers/core_provider.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/services/ai_service_manager.dart';
import 'package:spiral_journal/services/profile_service.dart';
import 'package:spiral_journal/services/journal_service.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:intl/intl.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _journalController = TextEditingController();
  final List<String> _selectedMoods = [];
  final List<String> _aiDetectedMoods = [];
  
  bool _isAnalyzing = false;
  bool _isSaving = false;
  String? _draftContent;
  String? _analysisInsight;
  String _userName = 'there'; // Default fallback name
  JournalEntry? _todaysEntry; // Track today's entry for editing
  String? _currentDraftId; // Track current draft ID for autosave

  @override
  void initState() {
    super.initState();
    _loadDraftContent();
    _loadUserName();
  }

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _loadDraftContent() async {
    // Load any existing draft content from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftContent = prefs.getString('journal_draft_content');
      final draftMoods = prefs.getStringList('journal_draft_moods') ?? [];
      
      if (draftContent != null && draftContent.isNotEmpty) {
        setState(() {
          _draftContent = draftContent;
          _selectedMoods.clear();
          _selectedMoods.addAll(draftMoods);
        });
        
        // Show recovery dialog
        if (mounted) {
          _showDraftRecoveryDialog(draftContent);
        }
      }
    } catch (e) {
      debugPrint('Error loading draft content: $e');
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
      
      setState(() {
        _draftContent = content;
      });
    } catch (e) {
      debugPrint('Error saving draft content: $e');
    }
  }

  Future<void> _clearDraftContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('journal_draft_content');
      await prefs.remove('journal_draft_moods');
      
      setState(() {
        _draftContent = null;
      });
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DesignTokens.getColorWithOpacity(DesignTokens.getBackgroundTertiary(context), 0.5),
                  borderRadius: BorderRadius.circular(8),
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

  void _showAnalysisInsight(dynamic analysisResult) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.psychology_rounded,
                color: DesignTokens.getPrimaryColor(context),
              ),
              const SizedBox(width: 8),
              const Text('AI Analysis'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (analysisResult.personalizedInsight.isNotEmpty) ...[
                  Text(
                    'Personal Insight:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    analysisResult.personalizedInsight,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],
                
                if (analysisResult.primaryEmotions.isNotEmpty) ...[
                  Text(
                    'Detected Emotions:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: analysisResult.primaryEmotions.map<Widget>((emotion) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: DesignTokens.getMoodColor(emotion),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          emotion,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                
                if (analysisResult.keyThemes.isNotEmpty) ...[
                  Text(
                    'Key Themes:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...analysisResult.keyThemes.map<Widget>((theme) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 6,
                            color: DesignTokens.getTextSecondary(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              theme,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _acceptAllAIMoods();
              },
              child: const Text('Accept Emotions'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _triggerAIAnalysis() async {
    if (_journalController.text.trim().isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _aiDetectedMoods.clear();
      _analysisInsight = null;
    });

    try {
      // Get AI service manager
      final aiManager = AIServiceManager();
      
      // Create a temporary journal entry for analysis
      final tempEntry = JournalEntry.create(
        content: _journalController.text.trim(),
        moods: _selectedMoods,
      );

      // Perform real AI analysis
      final analysisResult = await aiManager.performEmotionalAnalysis(tempEntry);
      
      setState(() {
        _aiDetectedMoods.clear();
        _aiDetectedMoods.addAll(analysisResult.primaryEmotions);
        _analysisInsight = analysisResult.personalizedInsight;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI analysis complete! Found ${analysisResult.primaryEmotions.length} emotions.'),
            backgroundColor: AppTheme.accentGreen,
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // Show analysis insight in a dialog
                _showAnalysisInsight(analysisResult);
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('AI Analysis error: $e');
      
      // Fallback to simple keyword-based analysis
      final detectedMoods = _simulateAIAnalysis(_journalController.text);
      
      setState(() {
        _aiDetectedMoods.clear();
        _aiDetectedMoods.addAll(detectedMoods);
        _analysisInsight = 'Basic analysis complete. AI service unavailable.';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using basic analysis. Found ${detectedMoods.length} emotions.'),
            backgroundColor: AppTheme.accentYellow,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  List<String> _simulateAIAnalysis(String content) {
    // Simple simulation of AI mood detection based on keywords
    final detectedMoods = <String>[];
    final contentLower = content.toLowerCase();
    
    if (contentLower.contains('happy') || contentLower.contains('joy') || contentLower.contains('great')) {
      detectedMoods.add('happy');
    }
    if (contentLower.contains('grateful') || contentLower.contains('thankful') || contentLower.contains('appreciate')) {
      detectedMoods.add('grateful');
    }
    if (contentLower.contains('excited') || contentLower.contains('amazing') || contentLower.contains('wonderful')) {
      detectedMoods.add('excited');
    }
    if (contentLower.contains('calm') || contentLower.contains('peaceful') || contentLower.contains('relaxed')) {
      detectedMoods.add('peaceful');
    }
    if (contentLower.contains('sad') || contentLower.contains('down') || contentLower.contains('upset')) {
      detectedMoods.add('sad');
    }
    if (contentLower.contains('anxious') || contentLower.contains('worried') || contentLower.contains('nervous')) {
      detectedMoods.add('anxious');
    }
    if (contentLower.contains('angry') || contentLower.contains('frustrated') || contentLower.contains('mad')) {
      detectedMoods.add('frustrated');
    }
    if (contentLower.contains('tired') || contentLower.contains('exhausted') || contentLower.contains('drained')) {
      detectedMoods.add('tired');
    }
    
    // If no specific moods detected, add some general ones based on content analysis
    if (detectedMoods.isEmpty) {
      if (contentLower.length > 100) {
        detectedMoods.add('reflective');
      }
      if (contentLower.contains('today') || contentLower.contains('work') || contentLower.contains('life')) {
        detectedMoods.add('contemplative');
      }
    }
    
    return detectedMoods.take(3).toList(); // Limit to 3 detected moods
  }

  void _acceptAllAIMoods() {
    setState(() {
      final newMoods = List<String>.from(_selectedMoods);
      for (final mood in _aiDetectedMoods) {
        final capitalizedMood = mood[0].toUpperCase() + mood.substring(1).toLowerCase();
        if (!newMoods.any((m) => m.toLowerCase() == mood.toLowerCase())) {
          newMoods.add(capitalizedMood);
        }
      }
      _selectedMoods.clear();
      _selectedMoods.addAll(newMoods);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${_aiDetectedMoods.length} AI-detected moods!'),
        backgroundColor: AppTheme.accentGreen,
      ),
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
                        content: Text('Today\'s entry: "${todaysEntry.content.length > 50 ? todaysEntry.content.substring(0, 50) + '...' : todaysEntry.content}"'),
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

    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final coreProvider = Provider.of<CoreProvider>(context, listen: false);

    // Create entry with AI-detected moods if available
    final allMoods = List<String>.from(_selectedMoods);
    for (final aiMood in _aiDetectedMoods) {
      final capitalizedMood = aiMood[0].toUpperCase() + aiMood.substring(1).toLowerCase();
      if (!allMoods.any((m) => m.toLowerCase() == aiMood.toLowerCase())) {
        allMoods.add(capitalizedMood);
      }
    }

    final success = await journalProvider.createEntry(
      content: _journalController.text.trim(),
      moods: allMoods,
    );

    if (mounted) {
      if (success) {
        // Clear draft content after successful save
        await _clearDraftContent();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _aiDetectedMoods.isNotEmpty 
                  ? 'Entry saved with AI insights! 🎉' 
                  : 'Entry saved successfully! 🎉'
            ),
            backgroundColor: AppTheme.accentGreen,
            action: _analysisInsight != null 
                ? SnackBarAction(
                    label: 'View Insight',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_analysisInsight!),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    },
                  )
                : null,
          ),
        );

        // Refresh cores after saving entry
        await coreProvider.refresh();

        // Refresh journal entries so they appear immediately in history
        await journalProvider.refresh();

        // Clear the form after successful save
        setState(() {
          _journalController.clear();
          _selectedMoods.clear();
          _aiDetectedMoods.clear();
          _analysisInsight = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save entry: ${journalProvider.error ?? 'Unknown error'}'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormatter = DateFormat('EEEE, MMMM d');

    return AdaptiveScaffold(
      backgroundColor: DesignTokens.getBackgroundPrimary(context),
      padding: EdgeInsets.zero, // Remove default padding to avoid double padding
      body: Container(
        decoration: BoxDecoration(
          gradient: DesignTokens.getPrimaryGradient(context),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with app title, date, and analysis counter
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: DesignTokens.getColorWithOpacity(
                            DesignTokens.getPrimaryColor(context), 
                            0.15
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          'assets/images/spiral_journal_icon.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to original icon if image fails to load
                            return Icon(
                              Icons.auto_stories_rounded,
                              color: DesignTokens.getPrimaryColor(context),
                              size: 24,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ResponsiveText(
                          'Spiral Journal',
                          baseFontSize: DesignTokens.fontSizeXXXL,
                          fontWeight: DesignTokens.fontWeightBold,
                          color: DesignTokens.getTextPrimary(context),
                        ),
                      ),
                      // Compact Analysis Counter aligned with title
                      const CompactAnalysisCounter(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ResponsiveText(
                    dateFormatter.format(now),
                    baseFontSize: DesignTokens.fontSizeM,
                    fontWeight: DesignTokens.fontWeightRegular,
                    color: DesignTokens.getTextTertiary(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Greeting
              ResponsiveText(
                'Hi $_userName, how are you feeling today?',
                baseFontSize: DesignTokens.fontSizeXXL,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: DesignTokens.getTextPrimary(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 24),
              
              // Mood Selector
              MoodSelector(
                selectedMoods: _selectedMoods,
                onMoodChanged: (moods) {
                  setState(() {
                    _selectedMoods.clear();
                    _selectedMoods.addAll(moods);
                  });
                },
                aiDetectedMoods: _aiDetectedMoods,
                isAnalyzing: _isAnalyzing,
                onAcceptAIMoods: _aiDetectedMoods.isNotEmpty ? _acceptAllAIMoods : null,
              ),
              
              const SizedBox(height: 24),
              
              // Journal Input
              Consumer<JournalProvider>(
                builder: (context, journalProvider, child) {
                  return JournalInput(
                    controller: _journalController,
                    onChanged: (text) {
                      // Handle text changes if needed
                    },
                    onSave: _saveEntry,
                    isSaving: journalProvider.isLoading,
                    isAnalyzing: _isAnalyzing,
                    onAutoSave: _saveDraftContent,
                    onTriggerAnalysis: _triggerAIAnalysis,
                    draftContent: _draftContent,
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Mind Reflection Card
              const MindReflectionCard(),
              
              const SizedBox(height: 24),
              
              // Your Cores Card
              const YourCoresCard(),
              
              const SizedBox(height: 100), // Extra space for bottom navigation
            ],
          ),
        ),
      ),
    );
  }
}

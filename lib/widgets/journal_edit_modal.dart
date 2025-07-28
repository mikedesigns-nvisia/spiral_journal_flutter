import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/design_system/responsive_layout.dart';
import 'package:spiral_journal/widgets/mood_selector.dart';
import 'package:spiral_journal/widgets/journal_input.dart';
import 'package:spiral_journal/providers/journal_provider.dart';
import 'package:spiral_journal/providers/core_provider_refactored.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/services/ai_service_manager.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:intl/intl.dart';

class JournalEditModal extends StatefulWidget {
  final JournalEntry entry;
  final VoidCallback? onSaved;
  final VoidCallback? onCancelled;

  const JournalEditModal({
    super.key,
    required this.entry,
    this.onSaved,
    this.onCancelled,
  });

  @override
  State<JournalEditModal> createState() => _JournalEditModalState();
}

class _JournalEditModalState extends State<JournalEditModal> {
  late TextEditingController _journalController;
  late List<String> _selectedMoods;
  final List<String> _aiDetectedMoods = [];
  
  bool _isAnalyzing = false;
  bool _isSaving = false;
  String? _analysisInsight;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _journalController = TextEditingController(text: widget.entry.content);
    _selectedMoods = List<String>.from(widget.entry.moods);
    
    // Listen for changes to track unsaved changes
    _journalController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _journalController.removeListener(_onContentChanged);
    _journalController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    final hasChanges = _journalController.text != widget.entry.content ||
        !_listsEqual(_selectedMoods, widget.entry.moods);
    
    if (hasChanges != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _triggerAIAnalysis() async {
    if (_journalController.text.trim().isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _aiDetectedMoods.clear();
      _analysisInsight = null;
    });

    try {
      final aiManager = AIServiceManager();
      final tempEntry = JournalEntry.create(
        content: _journalController.text.trim(),
        moods: _selectedMoods,
      );

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
          ),
        );
      }
    } catch (e) {
      // Fallback to simple analysis
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
    
    return detectedMoods.take(3).toList();
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

    setState(() {
      _isSaving = true;
    });

    try {
      final journalProvider = Provider.of<JournalProvider>(context, listen: false);
      final coreProvider = Provider.of<CoreProvider>(context, listen: false);

      // Create updated entry
      final updatedEntry = widget.entry.copyWith(
        content: _journalController.text.trim(),
        moods: _selectedMoods,
        updatedAt: DateTime.now(),
      );

      // Update the entry
      await journalProvider.updateEntry(updatedEntry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Entry updated successfully! 🎉'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );

        // Refresh cores and entries
        await coreProvider.refresh();
        await journalProvider.refresh();

        // Close modal and notify parent
        Navigator.of(context).pop();
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update entry: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Discard',
              style: TextStyle(color: AppTheme.accentRed),
            ),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: DesignTokens.getBackgroundPrimary(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DesignTokens.getBackgroundSecondary(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(
                    color: DesignTokens.getBackgroundTertiary(context),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: DesignTokens.getTextTertiary(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Header content
                  Row(
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        color: DesignTokens.getPrimaryColor(context),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ResponsiveText(
                              'Edit Entry',
                              baseFontSize: DesignTokens.fontSizeXL,
                              fontWeight: DesignTokens.fontWeightSemiBold,
                              color: DesignTokens.getTextPrimary(context),
                            ),
                            ResponsiveText(
                              DateFormat('EEEE, MMMM d • h:mm a').format(widget.entry.createdAt),
                              baseFontSize: DesignTokens.fontSizeS,
                              fontWeight: DesignTokens.fontWeightRegular,
                              color: DesignTokens.getTextTertiary(context),
                            ),
                          ],
                        ),
                      ),
                      // Close button
                      IconButton(
                        onPressed: () async {
                          if (await _onWillPop()) {
                            Navigator.of(context).pop();
                            widget.onCancelled?.call();
                          }
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: DesignTokens.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Modal Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mood Selector
                    MoodSelector(
                      selectedMoods: _selectedMoods,
                      onMoodChanged: (moods) {
                        setState(() {
                          _selectedMoods.clear();
                          _selectedMoods.addAll(moods);
                        });
                        _onContentChanged();
                      },
                      aiDetectedMoods: _aiDetectedMoods,
                       onAcceptAIMoods: _aiDetectedMoods.isNotEmpty ? _acceptAllAIMoods : null,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Journal Input
                    JournalInput(
                      controller: _journalController,
                      onChanged: (text) {
                        _onContentChanged();
                      },
                      onSave: _saveEntry,
                      isSaving: _isSaving,
                    ),
                    
                    const SizedBox(height: 100), // Extra space for bottom actions
                  ],
                ),
              ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DesignTokens.getBackgroundSecondary(context),
                border: Border(
                  top: BorderSide(
                    color: DesignTokens.getBackgroundTertiary(context),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          if (await _onWillPop()) {
                            Navigator.of(context).pop();
                            widget.onCancelled?.call();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: DesignTokens.getTextTertiary(context),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: DesignTokens.getTextSecondary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Save button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveEntry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.getPrimaryColor(context),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.save_rounded,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

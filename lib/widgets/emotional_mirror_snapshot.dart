import 'package:flutter/material.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/theme/app_theme.dart';

class EmotionalMirrorSnapshot extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onViewFullAnalysis;

  const EmotionalMirrorSnapshot({
    super.key,
    required this.entry,
    required this.onViewFullAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.getBackgroundSecondary(context),
            DesignTokens.getBackgroundTertiary(context),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Success header
          Icon(
            Icons.check_circle,
            color: AppTheme.accentGreen,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Entry Saved Successfully!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentGreen,
            ),
          ),
          const SizedBox(height: 24),
          
          // Mood visualization
          Text(
            'Your Emotional Snapshot',
            style: TextStyle(
              fontSize: 16,
              color: DesignTokens.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entry.moods.map((mood) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getMoodColor(mood).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getMoodColor(mood)),
              ),
              child: Text(
                mood,
                style: TextStyle(color: _getMoodColor(mood)),
              ),
            )).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // View full analysis button
          ElevatedButton.icon(
            onPressed: onViewFullAnalysis,
            icon: const Icon(Icons.psychology),
            label: const Text('View Full Emotional Analysis'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMoodColor(String mood) {
    // Add mood-to-color mapping similar to emotional mirror
    final moodLower = mood.toLowerCase();
    if (moodLower.contains('happy') || moodLower.contains('joy')) return AppTheme.accentGreen;
    if (moodLower.contains('grateful') || moodLower.contains('love')) return AppTheme.accentRed;
    if (moodLower.contains('content') || moodLower.contains('peaceful')) return Colors.grey;
    if (moodLower.contains('excited') || moodLower.contains('confident')) return AppTheme.primaryOrange;
    if (moodLower.contains('sad') || moodLower.contains('disappointed')) return Colors.blue;
    if (moodLower.contains('angry') || moodLower.contains('frustrated')) return AppTheme.accentRed;
    if (moodLower.contains('anxious') || moodLower.contains('worried')) return Colors.purple;
    if (moodLower.contains('stressed') || moodLower.contains('overwhelmed')) return Colors.orange;
    // Default mood color
    return AppTheme.primaryOrange;
  }
}
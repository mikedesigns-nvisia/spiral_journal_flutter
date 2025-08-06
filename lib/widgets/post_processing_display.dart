import 'package:flutter/material.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/design_system/component_library.dart';
import 'package:spiral_journal/design_system/responsive_layout.dart';
import 'package:spiral_journal/models/journal_entry.dart';

/// Widget that displays local processing results for journal entries
class PostProcessingDisplay extends StatelessWidget {
  final JournalEntry? journalEntry;
  final VoidCallback? onViewEntry;

  const PostProcessingDisplay({
    super.key,
    this.journalEntry,
    this.onViewEntry,
  });

  @override
  Widget build(BuildContext context) {
    // If no journal entry is available, show placeholder
    if (journalEntry == null) {
      return ComponentLibrary.gradientCard(
        gradient: DesignTokens.getCardGradient(context),
        child: _buildNoEntryState(context),
      );
    }

    return Column(
      children: [
        // Entry Summary Card
        _buildEntrySummaryCard(context, journalEntry!),
        
        SizedBox(height: DesignTokens.spaceL),
        
        // Mood Overview Card
        _buildMoodOverviewCard(context, journalEntry!),
        
        SizedBox(height: DesignTokens.spaceL),
        
        // Entry Details Card
        _buildEntryDetailsCard(context, journalEntry!),
      ],
    );
  }

  Widget _buildNoEntryState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.edit_note,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          SizedBox(height: DesignTokens.spaceM),
          Text(
            'No entry to display',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntrySummaryCard(BuildContext context, JournalEntry entry) {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Journal Entry',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDate(entry.date),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spaceM),
            Text(
              _getEntryPreview(entry.content),
              style: Theme.of(context).textTheme.bodyLarge,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (onViewEntry != null) ...[
              SizedBox(height: DesignTokens.spaceM),
              TextButton(
                onPressed: onViewEntry,
                child: const Text('View Full Entry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMoodOverviewCard(BuildContext context, JournalEntry entry) {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Moods',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: DesignTokens.spaceM),
            Wrap(
              spacing: DesignTokens.spaceS,
              runSpacing: DesignTokens.spaceS,
              children: entry.moods.map((mood) => _buildMoodChip(context, mood)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodChip(BuildContext context, String mood) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceM,
        vertical: DesignTokens.spaceXS,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        mood,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildEntryDetailsCard(BuildContext context, JournalEntry entry) {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Entry Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: DesignTokens.spaceM),
            _buildDetailRow(context, 'Day', entry.dayOfWeek),
            _buildDetailRow(context, 'Created', _formatDateTime(entry.createdAt)),
            if (entry.updatedAt != entry.createdAt)
              _buildDetailRow(context, 'Updated', _formatDateTime(entry.updatedAt)),
            _buildDetailRow(context, 'Status', _getStatusText(entry.status)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getEntryPreview(String content) {
    if (content.length <= 150) return content;
    return '${content.substring(0, 150)}...';
  }

  String _getStatusText(EntryStatus status) {
    switch (status) {
      case EntryStatus.draft:
        return 'Draft';
      case EntryStatus.saved:
        return 'Saved';
      case EntryStatus.processed:
        return 'Processed';
    }
  }
}
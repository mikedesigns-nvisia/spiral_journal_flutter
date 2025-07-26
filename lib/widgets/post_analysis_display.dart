import 'package:flutter/material.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/design_system/component_library.dart';
import 'package:spiral_journal/design_system/responsive_layout.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/services/emotional_analyzer.dart';

/// Widget that displays AI analysis results after a journal entry has been analyzed
class PostAnalysisDisplay extends StatelessWidget {
  final JournalEntry journalEntry;
  final EmotionalAnalysisResult analysisResult;
  final VoidCallback? onCreateNewEntry;

  const PostAnalysisDisplay({
    super.key,
    required this.journalEntry,
    required this.analysisResult,
    this.onCreateNewEntry,
  });

  @override
  Widget build(BuildContext context) {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header showing analysis completion
          _buildHeader(context),
          
          SizedBox(height: DesignTokens.spaceXL),
          
          // Show detected emotions
          _buildEmotionsSection(context),
          
          SizedBox(height: DesignTokens.spaceL),
          
          // Show personalized insight
          _buildInsightSection(context),
          
          SizedBox(height: DesignTokens.spaceL),
          
          // Show key themes
          if (analysisResult.keyThemes.isNotEmpty)
            _buildThemesSection(context),
          
          SizedBox(height: DesignTokens.spaceXL),
          
          // Action button to create new entry (if available)
          if (onCreateNewEntry != null)
            _buildNewEntryButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(DesignTokens.spaceM),
          decoration: BoxDecoration(
            color: DesignTokens.accentGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Icon(
            Icons.psychology_rounded,
            color: DesignTokens.accentGreen,
            size: DesignTokens.iconSizeL,
          ),
        ),
        SizedBox(width: DesignTokens.spaceL),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                'Analysis Complete',
                baseFontSize: DesignTokens.fontSizeXL,
                fontWeight: DesignTokens.fontWeightBold,
                color: DesignTokens.getTextPrimary(context),
              ),
              SizedBox(height: DesignTokens.spaceXS),
              ResponsiveText(
                'Your journal entry has been analyzed',
                baseFontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightRegular,
                color: DesignTokens.getTextSecondary(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Detected Emotions',
          baseFontSize: DesignTokens.fontSizeL,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.getTextPrimary(context),
        ),
        SizedBox(height: DesignTokens.spaceM),
        Wrap(
          spacing: DesignTokens.spaceS,
          runSpacing: DesignTokens.spaceS,
          children: analysisResult.primaryEmotions.take(5).map((emotion) {
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceM,
                vertical: DesignTokens.spaceS,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.accentBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                border: Border.all(
                  color: DesignTokens.accentBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ResponsiveText(
                emotion,
                baseFontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.accentBlue,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInsightSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Personal Insight',
          baseFontSize: DesignTokens.fontSizeL,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.getTextPrimary(context),
        ),
        SizedBox(height: DesignTokens.spaceM),
        Container(
          padding: EdgeInsets.all(DesignTokens.spaceL),
          decoration: BoxDecoration(
            color: DesignTokens.accentYellow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            border: Border.all(
              color: DesignTokens.accentYellow.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ResponsiveText(
            analysisResult.personalizedInsight,
            baseFontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightRegular,
            color: DesignTokens.getTextPrimary(context),
            maxLines: null,
          ),
        ),
      ],
    );
  }

  Widget _buildThemesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Key Themes',
          baseFontSize: DesignTokens.fontSizeL,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.getTextPrimary(context),
        ),
        SizedBox(height: DesignTokens.spaceM),
        Column(
          children: analysisResult.keyThemes.take(3).map((theme) {
            return Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spaceS),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    margin: EdgeInsets.only(
                      top: DesignTokens.spaceS,
                      right: DesignTokens.spaceM,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.getPrimaryColor(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: ResponsiveText(
                      theme,
                      baseFontSize: DesignTokens.fontSizeM,
                      fontWeight: DesignTokens.fontWeightRegular,
                      color: DesignTokens.getTextPrimary(context),
                      maxLines: null,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNewEntryButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: onCreateNewEntry,
        icon: Icon(
          Icons.edit_rounded,
          size: DesignTokens.iconSizeM,
        ),
        label: ResponsiveText(
          'Create New Entry',
          baseFontSize: DesignTokens.fontSizeM,
          fontWeight: DesignTokens.fontWeightMedium,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.getPrimaryColor(context),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceXL,
            vertical: DesignTokens.spaceL,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          ),
        ),
      ),
    );
  }
}
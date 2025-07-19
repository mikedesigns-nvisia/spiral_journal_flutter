import 'package:flutter/material.dart';
import 'dart:async';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/design_system/component_library.dart';
import 'package:spiral_journal/design_system/responsive_layout.dart';
import 'package:spiral_journal/widgets/loading_state_widget.dart' as loading_widget;
import 'package:spiral_journal/utils/animation_utils.dart';

class JournalInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback onSave;
  final bool isSaving;
  final bool isAnalyzing;
  final Function(String)? onAutoSave;
  final VoidCallback? onTriggerAnalysis;
  final String? draftContent;

  const JournalInput({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSave,
    this.isSaving = false,
    this.isAnalyzing = false,
    this.onAutoSave,
    this.onTriggerAnalysis,
    this.draftContent,
  });

  @override
  State<JournalInput> createState() => _JournalInputState();
}

class _JournalInputState extends State<JournalInput> {
  Timer? _autoSaveTimer;
  String _lastSavedContent = '';
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    // Restore draft content if available
    if (widget.draftContent != null && widget.draftContent!.isNotEmpty) {
      widget.controller.text = widget.draftContent!;
      _lastSavedContent = widget.draftContent!;
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String text) {
    widget.onChanged(text);
    
    // Check if content has changed
    if (text != _lastSavedContent) {
      setState(() {
        _hasUnsavedChanges = true;
      });
      
      // Cancel existing timer
      _autoSaveTimer?.cancel();
      
      // Start new auto-save timer (save after 2 seconds of inactivity)
      _autoSaveTimer = Timer(const Duration(seconds: 2), () {
        if (text.trim().isNotEmpty && widget.onAutoSave != null) {
          widget.onAutoSave!(text);
          setState(() {
            _lastSavedContent = text;
            _hasUnsavedChanges = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: DesignTokens.getBackgroundSecondary(context),
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(
          color: DesignTokens.getBackgroundTertiary(context),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.getColorWithOpacity(
              Colors.black,
              0.1,
            ),
            blurRadius: DesignTokens.elevationS,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(DesignTokens.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(height: DesignTokens.spaceL),
          _buildTextInput(context),
          _buildAnalysisIndicator(context),
          SizedBox(height: DesignTokens.spaceL),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceS),
      child: Row(
        children: [
          Expanded(
            child: ResponsiveText(
              'What\'s on your mind?',
              baseFontSize: DesignTokens.fontSizeXL,
              fontWeight: DesignTokens.fontWeightMedium,
              color: DesignTokens.getPrimaryColor(context),
            ),
          ),
          SizedBox(width: DesignTokens.spaceM),
          _buildSaveIndicator(context),
        ],
      ),
    );
  }

  Widget _buildSaveIndicator(BuildContext context) {
    if (_hasUnsavedChanges) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.edit,
            size: DesignTokens.iconSizeS,
            color: DesignTokens.getTextTertiary(context),
          ),
          SizedBox(width: DesignTokens.spaceXS),
          ResponsiveText(
            'Auto-saving...',
            baseFontSize: DesignTokens.fontSizeS,
            fontWeight: DesignTokens.fontWeightRegular,
            color: DesignTokens.getTextTertiary(context),
          ),
        ],
      );
    } else if (_lastSavedContent.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: DesignTokens.iconSizeS,
            color: DesignTokens.successColor,
          ),
          SizedBox(width: DesignTokens.spaceXS),
          ResponsiveText(
            'Saved',
            baseFontSize: DesignTokens.fontSizeS,
            fontWeight: DesignTokens.fontWeightRegular,
            color: DesignTokens.successColor,
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTextInput(BuildContext context) {
    final maxLines = 10; // Increased from 6 to 10 for more writing space
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceXS), // Reduced padding for wider input
      child: Container(
        key: const Key('journal_text_input'),
        child: ComponentLibrary.textField(
          context: context,
          label: '',
          hint: 'Share your thoughts, experiences, and reflections...\n\nTake your time to explore your feelings, describe your experiences, and reflect on what matters to you today.',
          controller: widget.controller,
          onChanged: _onTextChanged,
          maxLines: maxLines,
        ),
      ),
    );
  }

  Widget _buildAnalysisIndicator(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: widget.isAnalyzing ? null : 0,
      child: widget.isAnalyzing ? Column(
        children: [
          SizedBox(height: DesignTokens.spaceM),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceS),
            child: AnimationUtils.fadeScaleTransition(
              animation: const AlwaysStoppedAnimation(1.0),
              child: Container(
                padding: EdgeInsets.all(DesignTokens.spaceL),
                decoration: BoxDecoration(
                  color: DesignTokens.getColorWithOpacity(
                    DesignTokens.getPrimaryColor(context), 
                    0.1
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                  border: Border.all(
                    color: DesignTokens.getColorWithOpacity(
                      DesignTokens.getPrimaryColor(context), 
                      0.3
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    loading_widget.LoadingStateWidget(
                      type: loading_widget.LoadingType.dots,
                      size: DesignTokens.iconSizeM,
                      color: DesignTokens.getPrimaryColor(context),
                    ),
                    SizedBox(width: DesignTokens.spaceL),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ResponsiveText(
                            'AI Analysis in Progress',
                            baseFontSize: DesignTokens.fontSizeM,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                            color: DesignTokens.getTextPrimary(context),
                          ),
                          SizedBox(height: DesignTokens.spaceXS),
                          ResponsiveText(
                            'Analyzing your emotions and updating your cores...',
                            baseFontSize: DesignTokens.fontSizeS,
                            fontWeight: DesignTokens.fontWeightRegular,
                            color: DesignTokens.getTextSecondary(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ) : const SizedBox.shrink(),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceS),
      child: Row(
        children: [
          _buildSecondaryActions(context),
          Spacer(),
          // Show word count or character count for user feedback
          _buildWordCount(context),
          SizedBox(width: DesignTokens.spaceM),
          // Save button
          _buildSaveButton(context),
        ],
      ),
    );
  }

  Widget _buildSecondaryActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Voice input button
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Voice input coming soon!'),
                duration: const Duration(seconds: 2),
                backgroundColor: DesignTokens.getPrimaryColor(context),
              ),
            );
          },
          icon: Icon(Icons.mic_rounded, size: DesignTokens.iconSizeM),
          style: IconButton.styleFrom(
            foregroundColor: DesignTokens.getTextTertiary(context),
            backgroundColor: DesignTokens.getBackgroundTertiary(context),
            padding: EdgeInsets.all(DesignTokens.spaceM),
            minimumSize: Size(DesignTokens.buttonHeight, DesignTokens.buttonHeight),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          tooltip: 'Voice input',
        ),
      ],
    );
  }

  Widget _buildWordCount(BuildContext context) {
    final text = widget.controller.text;
    final wordCount = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    
    if (wordCount == 0) {
      return const SizedBox.shrink();
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.edit_note_rounded,
          size: DesignTokens.iconSizeS,
          color: DesignTokens.getTextTertiary(context),
        ),
        SizedBox(width: DesignTokens.spaceXS),
        ResponsiveText(
          '$wordCount ${wordCount == 1 ? 'word' : 'words'}',
          baseFontSize: DesignTokens.fontSizeS,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.getTextTertiary(context),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    final hasContent = widget.controller.text.trim().isNotEmpty;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: IconButton(
        onPressed: hasContent && !widget.isSaving ? widget.onSave : null,
        icon: widget.isSaving 
            ? SizedBox(
                width: DesignTokens.iconSizeM,
                height: DesignTokens.iconSizeM,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              )
            : Icon(
                Icons.save_rounded,
                size: DesignTokens.iconSizeM,
                color: Colors.white,
              ),
        style: IconButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: hasContent 
              ? DesignTokens.getPrimaryColor(context)
              : DesignTokens.getTextTertiary(context),
          padding: EdgeInsets.all(DesignTokens.spaceM),
          minimumSize: Size(DesignTokens.buttonHeight, DesignTokens.buttonHeight),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        tooltip: hasContent ? 'Save entry' : 'Write something to save',
      ),
    );
  }

}

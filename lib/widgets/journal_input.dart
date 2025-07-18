import 'package:flutter/material.dart';
import 'dart:async';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/design_system/component_library.dart';
import 'package:spiral_journal/design_system/responsive_layout.dart';
import 'package:spiral_journal/widgets/loading_state_widget.dart' as loading_widget;
import 'package:spiral_journal/utils/animation_utils.dart';
import 'package:spiral_journal/utils/iphone_detector.dart';

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
    return KeyboardAwareScrollView(
      child: AdaptiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
            _buildTextInput(context),
            _buildAnalysisIndicator(context),
            AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ResponsiveText(
            'What\'s on your mind?',
            baseFontSize: DesignTokens.fontSizeXL,
            fontWeight: DesignTokens.fontWeightMedium,
            color: DesignTokens.getPrimaryColor(context),
          ),
        ),
        _buildSaveIndicator(context),
      ],
    );
  }

  Widget _buildSaveIndicator(BuildContext context) {
    if (_hasUnsavedChanges) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.edit,
            size: iPhoneDetector.getAdaptiveIconSize(context, base: DesignTokens.iconSizeS),
            color: DesignTokens.getTextTertiary(context),
          ),
          AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceXS),
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
            size: iPhoneDetector.getAdaptiveIconSize(context, base: DesignTokens.iconSizeS),
            color: DesignTokens.successColor,
          ),
          AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceXS),
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
    final maxLines = iPhoneDetector.isCompactiPhone(context) ? 4 : 6;
    
    return ComponentLibrary.textField(
      label: '',
      hint: 'Share your thoughts, experiences, and reflections...',
      controller: widget.controller,
      onChanged: _onTextChanged,
      maxLines: maxLines,
    );
  }

  Widget _buildAnalysisIndicator(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: widget.isAnalyzing ? null : 0,
      child: widget.isAnalyzing ? Column(
        children: [
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceM),
          AnimationUtils.fadeScaleTransition(
            animation: const AlwaysStoppedAnimation(1.0),
            child: Container(
              padding: iPhoneDetector.getAdaptivePadding(context),
              decoration: BoxDecoration(
                color: DesignTokens.getColorWithOpacity(
                  DesignTokens.getPrimaryColor(context), 
                  0.1
                ),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
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
                    size: iPhoneDetector.getAdaptiveIconSize(context, base: 16),
                    color: DesignTokens.getPrimaryColor(context),
                  ),
                  AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceM),
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
        ],
      ) : const SizedBox.shrink(),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSecondaryActions(context),
        _buildSaveButton(context),
      ],
    );
  }

  Widget _buildSecondaryActions(BuildContext context) {
    final iconSize = iPhoneDetector.getAdaptiveIconSize(context, base: DesignTokens.iconSizeM);
    final buttonPadding = iPhoneDetector.getAdaptivePadding(context, compact: 8, regular: 12, large: 16);
    
    return Row(
      children: [
        // Voice input button
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Voice input coming soon!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: Icon(Icons.mic_rounded, size: iconSize),
          style: IconButton.styleFrom(
            foregroundColor: DesignTokens.getTextTertiary(context),
            backgroundColor: Theme.of(context).brightness == Brightness.dark 
                ? DesignTokens.darkBackgroundTertiary 
                : DesignTokens.backgroundTertiary,
            padding: buttonPadding,
          ),
          tooltip: 'Voice input',
        ),
        
        AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceS),
        
        // AI Analysis trigger button
        if (widget.onTriggerAnalysis != null && !widget.isAnalyzing)
          IconButton(
            onPressed: widget.controller.text.trim().isNotEmpty 
                ? widget.onTriggerAnalysis 
                : null,
            icon: Icon(Icons.psychology_rounded, size: iconSize),
            style: IconButton.styleFrom(
              foregroundColor: widget.controller.text.trim().isNotEmpty
                  ? DesignTokens.getPrimaryColor(context)
                  : DesignTokens.getTextTertiary(context),
              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                  ? DesignTokens.darkBackgroundTertiary 
                  : DesignTokens.backgroundTertiary,
              padding: buttonPadding,
            ),
            tooltip: 'Analyze with AI',
          ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return AdaptiveButton(
      text: widget.isSaving 
          ? 'Saving...' 
          : widget.isAnalyzing 
              ? 'Analyzing...' 
              : 'Save Entry',
      onPressed: (widget.isSaving || widget.isAnalyzing) ? null : () {
        AnimationUtils.mediumImpact();
        widget.onSave();
      },
      isLoading: widget.isSaving,
      icon: Icons.save_rounded,
      type: ButtonType.primary,
    );
  }
}

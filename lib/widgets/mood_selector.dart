import 'package:flutter/material.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/design_system/component_library.dart';
import 'package:spiral_journal/design_system/heading_system.dart';
import 'package:spiral_journal/services/journal_service.dart';

class MoodSelector extends StatelessWidget {
  final List<String> selectedMoods;
  final Function(List<String>) onMoodChanged;
  final List<String> aiDetectedMoods;
  final bool isAnalyzing;
  final VoidCallback? onAcceptAIMoods;

  const MoodSelector({
    super.key,
    required this.selectedMoods,
    required this.onMoodChanged,
    this.aiDetectedMoods = const [],
    this.isAnalyzing = false,
    this.onAcceptAIMoods,
  });

  List<String> get availableMoods => JournalService().availableMoods;
  
  // Primary moods shown first
  List<String> get primaryMoods => [
    'happy', 'content', 'energetic', 'grateful', 'peaceful'
  ];
  
  // Secondary moods in carousel
  List<String> get secondaryMoods => availableMoods
      .where((mood) => !primaryMoods.contains(mood.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return ComponentLibrary.card(
      context: context,
      padding: ComponentTokens.moodSelectorPadding,
      hasBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI-detected moods section
          if (aiDetectedMoods.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DesignTokens.spaceM),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology_rounded,
                        size: DesignTokens.iconSizeS,
                        color: DesignTokens.getPrimaryColor(context),
                      ),
                      const SizedBox(width: DesignTokens.spaceS),
                      Expanded(
                        child: Text(
                          'AI detected these emotions:',
                          style: HeadingSystem.getTitleMedium(context).copyWith(
                            color: DesignTokens.getPrimaryColor(context),
                          ),
                        ),
                      ),
                      if (onAcceptAIMoods != null)
                        ComponentLibrary.textButton(
                          text: 'Accept All',
                          onPressed: onAcceptAIMoods,
                          size: ButtonSize.small,
                        ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceS),
                  Wrap(
                    spacing: ComponentTokens.moodSelectorSpacing,
                    runSpacing: ComponentTokens.moodSelectorRunSpacing,
                    children: aiDetectedMoods.map((mood) {
                      final isAlreadySelected = selectedMoods.any((selected) => 
                          selected.toLowerCase() == mood.toLowerCase());
                      
                      return ComponentLibrary.moodChip(
                        label: _capitalizeMood(mood),
                        isSelected: isAlreadySelected,
                        moodType: mood,
                        onTap: () {
                          if (!isAlreadySelected) {
                            final newMoods = List<String>.from(selectedMoods);
                            newMoods.add(_capitalizeMood(mood));
                            onMoodChanged(newMoods);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceL),
          ],
          
          // AI analysis in progress indicator
          if (isAnalyzing) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DesignTokens.spaceM),
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
                  SizedBox(
                    width: DesignTokens.iconSizeS,
                    height: DesignTokens.iconSizeS,
                    child: CircularProgressIndicator(
                      strokeWidth: DesignTokens.loadingStrokeWidth,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        DesignTokens.getPrimaryColor(context)
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceM),
                  Expanded(
                    child: Text(
                      'AI is analyzing your emotions...',
                      style: HeadingSystem.getTitleMedium(context).copyWith(
                        color: DesignTokens.getPrimaryColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceL),
          ],
          
          // Primary moods - always visible
          Wrap(
            spacing: ComponentTokens.moodSelectorSpacing,
            runSpacing: ComponentTokens.moodSelectorRunSpacing,
            children: primaryMoods.map((mood) {
              final isSelected = selectedMoods.any((selected) => 
                  selected.toLowerCase() == mood.toLowerCase());
              
              return ComponentLibrary.moodChip(
                label: _capitalizeMood(mood),
                isSelected: isSelected,
                moodType: mood,
                onTap: () {
                  final moodCapitalized = _capitalizeMood(mood);
                  final newMoods = List<String>.from(selectedMoods);
                  if (isSelected) {
                    newMoods.removeWhere((m) => 
                        m.toLowerCase() == mood.toLowerCase());
                  } else {
                    newMoods.add(moodCapitalized);
                  }
                  onMoodChanged(newMoods);
                },
              );
            }).toList(),
          ),
          
          if (secondaryMoods.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.spaceL),
            
            // "More moods" section with carousel
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'More moods:',
                      style: HeadingSystem.getTitleMedium(context).copyWith(
                        color: DesignTokens.getTextSecondary(context),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      'Swipe to see more →',
                      style: HeadingSystem.getBodySmall(context).copyWith(
                        color: DesignTokens.getTextTertiary(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: DesignTokens.spaceS),
            
            // Horizontal scrollable carousel for additional moods
            SizedBox(
              height: ComponentTokens.moodChipHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: secondaryMoods.length,
                itemBuilder: (context, index) {
                  final mood = secondaryMoods[index];
                  final isSelected = selectedMoods.any((selected) => 
                      selected.toLowerCase() == mood.toLowerCase());
                  
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < secondaryMoods.length - 1 
                          ? DesignTokens.spaceS 
                          : 0,
                    ),
                    child: ComponentLibrary.moodChip(
                      label: _capitalizeMood(mood),
                      isSelected: isSelected,
                      moodType: mood,
                      onTap: () {
                        final moodCapitalized = _capitalizeMood(mood);
                        final newMoods = List<String>.from(selectedMoods);
                        if (isSelected) {
                          newMoods.removeWhere((m) => 
                              m.toLowerCase() == mood.toLowerCase());
                        } else {
                          newMoods.add(moodCapitalized);
                        }
                        onMoodChanged(newMoods);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
          
          // Selected moods summary
          if (selectedMoods.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.spaceL),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DesignTokens.spaceM),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: DesignTokens.iconSizeS,
                        color: DesignTokens.getPrimaryColor(context),
                      ),
                      const SizedBox(width: DesignTokens.spaceS),
                      Expanded(
                        child: Text(
                          'Selected moods:',
                          style: HeadingSystem.getBodySmall(context).copyWith(
                            fontWeight: DesignTokens.fontWeightMedium,
                            color: DesignTokens.getTextSecondary(context),
                          ),
                        ),
                      ),
                      if (selectedMoods.length > 1)
                        ComponentLibrary.textButton(
                          text: 'Clear',
                          onPressed: () => onMoodChanged([]),
                          size: ButtonSize.small,
                        ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceXS),
                  Wrap(
                    spacing: DesignTokens.spaceXS,
                    runSpacing: DesignTokens.spaceXS,
                    children: selectedMoods.map((mood) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spaceS, 
                          vertical: DesignTokens.spaceXXS,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.getColorWithOpacity(
                            DesignTokens.getMoodColor(mood), 
                            0.2
                          ),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                        ),
                        child: Text(
                          mood,
                          style: HeadingSystem.getLabelSmall(context).copyWith(
                            color: DesignTokens.getTextSecondary(context),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  String _capitalizeMood(String mood) {
    return mood[0].toUpperCase() + mood.substring(1).toLowerCase();
  }
}

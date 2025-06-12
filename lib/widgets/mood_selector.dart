import 'package:flutter/material.dart';
import 'package:spiral_journal/theme/app_theme.dart';

class MoodSelector extends StatelessWidget {
  final List<String> selectedMoods;
  final Function(List<String>) onMoodChanged;

  const MoodSelector({
    super.key,
    required this.selectedMoods,
    required this.onMoodChanged,
  });

  final List<String> availableMoods = const [
    'Happy',
    'Content', 
    'Unsure',
    'Sad',
    'Energetic',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableMoods.map((mood) {
                final isSelected = selectedMoods.contains(mood);
                return FilterChip(
                  label: Text(mood),
                  selected: isSelected,
                  onSelected: (selected) {
                    final newMoods = List<String>.from(selectedMoods);
                    if (selected) {
                      newMoods.add(mood);
                    } else {
                      newMoods.remove(mood);
                    }
                    onMoodChanged(newMoods);
                  },
                  backgroundColor: AppTheme.backgroundTertiary,
                  selectedColor: AppTheme.getMoodColor(mood),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

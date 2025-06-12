import 'package:flutter/material.dart';
import 'package:spiral_journal/theme/app_theme.dart';

class JournalInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const JournalInput({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What\'s on your mind?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              onChanged: onChanged,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Share your thoughts, experiences, and reflections...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Voice input functionality
                  },
                  icon: const Icon(Icons.mic_rounded),
                  label: const Text('Voice'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textTertiary,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Save functionality
                    if (controller.text.isNotEmpty) {
                      // Handle save logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Entry saved!'),
                          backgroundColor: AppTheme.accentGreen,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Entry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

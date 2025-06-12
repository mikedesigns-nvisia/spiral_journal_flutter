import 'package:flutter/material.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/widgets/mood_selector.dart';
import 'package:spiral_journal/widgets/journal_input.dart';
import 'package:spiral_journal/widgets/mind_reflection_card.dart';
import 'package:spiral_journal/widgets/your_cores_card.dart';
import 'package:intl/intl.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _journalController = TextEditingController();
  final List<String> _selectedMoods = ['Happy', 'Content'];

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormatter = DateFormat('EEEE, MMMM d');

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with app title and date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentYellow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            color: AppTheme.primaryOrange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Spiral Journal',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateFormatter.format(now),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Greeting
                Text(
                  'Hi Kenzie, How are you feeling today?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
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
                ),
                
                const SizedBox(height: 24),
                
                // Journal Input
                JournalInput(
                  controller: _journalController,
                  onChanged: (text) {
                    // Handle text changes if needed
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
      ),
    );
  }
}

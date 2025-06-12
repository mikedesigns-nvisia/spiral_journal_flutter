import 'package:flutter/material.dart';
import 'package:spiral_journal/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentYellow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: AppTheme.primaryOrange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Settings Options
              _buildSettingsSection(
                'Account',
                [
                  _buildSettingsItem(Icons.person, 'Profile', 'Manage your personal information'),
                  _buildSettingsItem(Icons.security, 'Privacy', 'Data and privacy settings'),
                ],
              ),
              
              const SizedBox(height: 24),
              
              _buildSettingsSection(
                'Journal',
                [
                  _buildSettingsItem(Icons.notifications, 'Reminders', 'Set daily journaling reminders'),
                  _buildSettingsItem(Icons.backup, 'Backup', 'Sync and backup your entries'),
                  _buildSettingsItem(Icons.psychology, 'AI Insights', 'Customize emotional analysis'),
                ],
              ),
              
              const SizedBox(height: 24),
              
              _buildSettingsSection(
                'App',
                [
                  _buildSettingsItem(Icons.palette, 'Theme', 'Light mode'),
                  _buildSettingsItem(Icons.language, 'Language', 'English'),
                  _buildSettingsItem(Icons.help, 'Help & Support', 'Get help and send feedback'),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // App Version
              Center(
                child: Text(
                  'Spiral Journal v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ),
              
              const SizedBox(height: 100), // Extra space for bottom navigation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryOrange,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryOrange),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.textTertiary,
      ),
      onTap: () {
        // Handle settings item tap
      },
    );
  }
}

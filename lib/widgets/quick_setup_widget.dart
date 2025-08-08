import 'package:flutter/material.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import '../controllers/onboarding_controller.dart';
import '../services/theme_service.dart';

/// Quick setup widget for configuring basic app preferences during onboarding
class QuickSetupWidget extends StatelessWidget {
  final OnboardingController controller;
  final VoidCallback? onConfigChanged;

  const QuickSetupWidget({
    super.key,
    required this.controller,
    this.onConfigChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        color: DesignTokens.getBackgroundSecondary(context),
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(
          color: DesignTokens.getBackgroundTertiary(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theme Selection
          _buildThemeSelection(context),
          
          SizedBox(height: DesignTokens.spaceL),
          
          // Text Size Selection
          _buildTextSizeSelection(context),
          
          SizedBox(height: DesignTokens.spaceL),
          
          // Notifications Toggle
          _buildNotificationsToggle(context),
          
          SizedBox(height: DesignTokens.spaceL),
          
          // PIN setup removed - using biometrics-only authentication
        ],
      ),
    );
  }

  Widget _buildThemeSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme',
          style: DesignTokens.getTextStyle(
            fontSize: DesignTokens.fontSizeL,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.getTextPrimary(context),
          ),
        ),
        SizedBox(height: DesignTokens.spaceM),
        Row(
          children: ['Light', 'Dark', 'Auto'].map((theme) {
            final isSelected = controller.quickSetupConfig.theme == theme;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: theme != 'Auto' ? DesignTokens.spaceS : 0,
                ),
                child: _buildSelectionChip(
                  context: context,
                  label: theme,
                  isSelected: isSelected,
                  onTap: () async {
                    controller.updateThemePreference(theme);
                    
                    // Apply theme change immediately for real-time preview
                    final themeService = ThemeService();
                    await themeService.initialize();
                    
                    ThemeMode themeMode;
                    switch (theme.toLowerCase()) {
                      case 'light':
                        themeMode = ThemeMode.light;
                        break;
                      case 'dark':
                        themeMode = ThemeMode.dark;
                        break;
                      case 'auto':
                      default:
                        themeMode = ThemeMode.system;
                        break;
                    }
                    
                    await themeService.setThemeMode(themeMode);
                    onConfigChanged?.call();
                  },
                  icon: _getThemeIcon(theme),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextSizeSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Text Size',
          style: DesignTokens.getTextStyle(
            fontSize: DesignTokens.fontSizeL,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.getTextPrimary(context),
          ),
        ),
        SizedBox(height: DesignTokens.spaceM),
        Row(
          children: ['Small', 'Medium', 'Large'].map((size) {
            final isSelected = controller.quickSetupConfig.textSize == size;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: size != 'Large' ? DesignTokens.spaceS : 0,
                ),
                child: _buildSelectionChip(
                  context: context,
                  label: size,
                  isSelected: isSelected,
                  onTap: () {
                    controller.updateTextSizePreference(size);
                    onConfigChanged?.call();
                  },
                  icon: _getTextSizeIcon(size),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotificationsToggle(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.notifications_outlined,
          color: DesignTokens.getTextSecondary(context),
          size: 24,
        ),
        SizedBox(width: DesignTokens.spaceM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Reminders',
                style: DesignTokens.getTextStyle(
                  fontSize: DesignTokens.fontSizeL,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: DesignTokens.getTextPrimary(context),
                ),
              ),
              Text(
                'Gentle reminders to journal',
                style: DesignTokens.getTextStyle(
                  fontSize: DesignTokens.fontSizeM,
                  fontWeight: DesignTokens.fontWeightRegular,
                  color: DesignTokens.getTextSecondary(context),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: controller.quickSetupConfig.notifications,
          onChanged: (value) {
            controller.updateNotificationsPreference(value);
            onConfigChanged?.call();
          },
          activeColor: DesignTokens.getPrimaryColor(context),
        ),
      ],
    );
  }

  // PIN setup toggle removed - using biometrics-only authentication

  Widget _buildSelectionChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(DesignTokens.spaceM),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignTokens.getPrimaryColor(context)
              : DesignTokens.getBackgroundTertiary(context),
          borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
          border: Border.all(
            color: isSelected
                ? DesignTokens.getPrimaryColor(context)
                : DesignTokens.getBackgroundTertiary(context),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : DesignTokens.getTextSecondary(context),
                size: 20,
              ),
              SizedBox(height: DesignTokens.spaceXS),
            ],
            Text(
              label,
              style: DesignTokens.getTextStyle(
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightMedium,
                color: isSelected
                    ? Colors.white
                    : DesignTokens.getTextPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getThemeIcon(String theme) {
    switch (theme) {
      case 'Light':
        return Icons.light_mode;
      case 'Dark':
        return Icons.dark_mode;
      case 'Auto':
        return Icons.auto_mode;
      default:
        return Icons.brightness_auto;
    }
  }

  IconData _getTextSizeIcon(String size) {
    switch (size) {
      case 'Small':
        return Icons.text_decrease;
      case 'Medium':
        return Icons.text_fields;
      case 'Large':
        return Icons.text_increase;
      default:
        return Icons.text_fields;
    }
  }
}

/// Alternative quick setup widget with minimal configuration
class MinimalQuickSetupWidget extends StatelessWidget {
  final OnboardingController controller;
  final VoidCallback? onConfigChanged;

  const MinimalQuickSetupWidget({
    super.key,
    required this.controller,
    this.onConfigChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        color: DesignTokens.getBackgroundSecondary(context),
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(
          color: DesignTokens.getBackgroundTertiary(context),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Theme Selection Only
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                color: DesignTokens.getTextSecondary(context),
                size: 24,
              ),
              SizedBox(width: DesignTokens.spaceM),
              Expanded(
                child: Text(
                  'Theme',
                  style: DesignTokens.getTextStyle(
                    fontSize: DesignTokens.fontSizeL,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: DesignTokens.getTextPrimary(context),
                  ),
                ),
              ),
              DropdownButton<String>(
                value: controller.quickSetupConfig.theme,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    controller.updateThemePreference(newValue);
                    onConfigChanged?.call();
                  }
                },
                items: ['Light', 'Dark', 'Auto'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                underline: Container(),
                style: DesignTokens.getTextStyle(
                  fontSize: DesignTokens.fontSizeM,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: DesignTokens.getTextPrimary(context),
                ),
              ),
            ],
          ),
          
          SizedBox(height: DesignTokens.spaceL),
          
          // Notifications Toggle
          Row(
            children: [
              Icon(
                Icons.notifications_outlined,
                color: DesignTokens.getTextSecondary(context),
                size: 24,
              ),
              SizedBox(width: DesignTokens.spaceM),
              Expanded(
                child: Text(
                  'Daily Reminders',
                  style: DesignTokens.getTextStyle(
                    fontSize: DesignTokens.fontSizeL,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: DesignTokens.getTextPrimary(context),
                  ),
                ),
              ),
              Switch(
                value: controller.quickSetupConfig.notifications,
                onChanged: (value) {
                  controller.updateNotificationsPreference(value);
                  onConfigChanged?.call();
                },
                activeColor: DesignTokens.getPrimaryColor(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

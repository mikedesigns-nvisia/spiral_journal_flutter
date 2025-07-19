import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Debug script to help diagnose and fix splash screen issues
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    final prefs = await SharedPreferences.getInstance();
    
    print('=== SPLASH SCREEN DEBUG INFO ===');
    
    // Check all stored preferences
    final keys = prefs.getKeys();
    print('All stored keys:');
    for (final key in keys) {
      final value = prefs.get(key);
      print('  $key: $value');
    }
    
    print('\n=== SPLASH SCREEN SPECIFIC SETTINGS ===');
    
    // Check splash screen specific settings
    final splashEnabled = prefs.getBool('splashScreenEnabled');
    print('splashScreenEnabled: $splashEnabled');
    
    // Check onboarding status
    final onboardingCompleted = prefs.getBool('onboarding_completed');
    print('onboarding_completed: $onboardingCompleted');
    
    print('\n=== FIXING SPLASH SCREEN ISSUE ===');
    
    // Force disable splash screen temporarily
    await prefs.setBool('splashScreenEnabled', false);
    print('✅ Disabled splash screen');
    
    // Reset onboarding to see the new slide
    await prefs.remove('onboarding_completed');
    await prefs.remove('quick_setup_config');
    print('✅ Reset onboarding state');
    
    print('\n=== VERIFICATION ===');
    print('splashScreenEnabled: ${prefs.getBool('splashScreenEnabled')}');
    print('onboarding_completed: ${prefs.getBool('onboarding_completed')}');
    
    print('\n✅ Debug complete! Restart the app to see the onboarding flow.');
    
  } catch (e) {
    print('❌ Error during debug: $e');
  }
}
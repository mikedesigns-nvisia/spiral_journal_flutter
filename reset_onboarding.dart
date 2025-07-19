import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple script to reset onboarding state for testing
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove onboarding completion flag
    await prefs.remove('onboarding_completed');
    
    // Remove quick setup config
    await prefs.remove('quick_setup_config');
    
    // Also remove any other onboarding-related keys
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.contains('onboarding') || key.contains('setup')) {
        await prefs.remove(key);
        print('Removed key: $key');
      }
    }
    
    print('✅ Onboarding state has been reset successfully!');
    print('You can now see the onboarding flow when you restart the app.');
    
  } catch (e) {
    print('❌ Error resetting onboarding: $e');
  }
}
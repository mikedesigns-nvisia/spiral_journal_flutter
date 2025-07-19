import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

/// Service for managing user profile data
/// Handles local storage of basic profile information for TestFlight version
class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  static const String _profileKey = 'user_profile';
  static const String _profileSetupCompleteKey = 'profile_setup_complete';

  UserProfile? _cachedProfile;

  /// Check if user has completed profile setup
  Future<bool> hasProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSetupComplete = prefs.getBool(_profileSetupCompleteKey) ?? false;
      
      if (!hasSetupComplete) {
        return false;
      }

      // Double-check by trying to load the profile
      final profile = await getProfile();
      return profile != null;
    } catch (e) {
      debugPrint('ProfileService hasProfile error: $e');
      return false;
    }
  }

  /// Get the current user profile
  Future<UserProfile?> getProfile() async {
    // Return cached profile if available
    if (_cachedProfile != null) {
      return _cachedProfile;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);
      
      if (profileJson == null) {
        return null;
      }

      final profileMap = json.decode(profileJson) as Map<String, dynamic>;
      _cachedProfile = UserProfile.fromJson(profileMap);
      return _cachedProfile;
    } catch (e) {
      debugPrint('ProfileService getProfile error: $e');
      return null;
    }
  }

  /// Save user profile
  Future<bool> saveProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = json.encode(profile.toJson());
      
      // Save profile data
      await prefs.setString(_profileKey, profileJson);
      
      // Mark profile setup as complete
      await prefs.setBool(_profileSetupCompleteKey, true);
      
      // Update cache
      _cachedProfile = profile;
      
      debugPrint('ProfileService: Profile saved successfully for ${profile.firstName}');
      return true;
    } catch (e) {
      debugPrint('ProfileService saveProfile error: $e');
      return false;
    }
  }

  /// Update existing profile
  Future<bool> updateProfile(UserProfile updatedProfile) async {
    return await saveProfile(updatedProfile);
  }

  /// Clear profile data (for testing or reset)
  Future<bool> clearProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove profile data
      await prefs.remove(_profileKey);
      await prefs.remove(_profileSetupCompleteKey);
      
      // Clear cache
      _cachedProfile = null;
      
      debugPrint('ProfileService: Profile cleared successfully');
      return true;
    } catch (e) {
      debugPrint('ProfileService clearProfile error: $e');
      return false;
    }
  }

  /// Get user's display name (first name)
  Future<String> getDisplayName() async {
    final profile = await getProfile();
    return profile?.displayName ?? 'User';
  }

  /// Get user's age
  Future<int?> getUserAge() async {
    final profile = await getProfile();
    return profile?.age;
  }

  /// Validate profile data before saving
  bool validateProfile({
    required String firstName,
    required DateTime birthday,
  }) {
    // Check first name
    if (firstName.trim().isEmpty) {
      return false;
    }

    if (firstName.trim().length < 2) {
      return false;
    }

    // Check birthday
    final now = DateTime.now();
    final age = now.year - birthday.year;
    
    // Must be at least 13 years old (App Store requirement)
    if (age < 13) {
      return false;
    }

    // Can't be more than 120 years old (reasonable limit)
    if (age > 120) {
      return false;
    }

    // Birthday can't be in the future
    if (birthday.isAfter(now)) {
      return false;
    }

    return true;
  }

  /// Get profile setup status for debugging
  Future<Map<String, dynamic>> getProfileStatus() async {
    try {
      final hasProfileSetup = await hasProfile();
      final profile = await getProfile();
      
      return {
        'hasProfile': hasProfileSetup,
        'profileExists': profile != null,
        'firstName': profile?.firstName,
        'age': profile?.age,
        'setupComplete': hasProfileSetup,
      };
    } catch (e) {
      return {
        'hasProfile': false,
        'profileExists': false,
        'error': e.toString(),
      };
    }
  }

  /// Initialize service (called during app startup)
  Future<void> initialize() async {
    try {
      // Pre-load profile into cache
      await getProfile();
      debugPrint('ProfileService: Initialized successfully');
    } catch (e) {
      debugPrint('ProfileService initialization error: $e');
    }
  }
}

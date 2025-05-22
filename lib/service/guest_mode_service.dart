import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_screen.dart';

class GuestModeService {
  // Check if feature is restricted
  static Future<bool> isFeatureRestricted(String featureKey) async {
    final prefs = await SharedPreferences.getInstance();
    final isGuestMode = prefs.getBool('isGuestMode') ?? false;

    if (!isGuestMode) {
      return false; // Not restricted if not in guest mode
    }

    // List of features restricted in guest mode
    const restrictedFeatures = [
      'profile_edit',
      'workout_save',
      'nutrition_tracking',
      'progress_tracking',
      'account_settings',
    ];

    return restrictedFeatures.contains(featureKey);
  }

  // Show restriction dialog
  static void showRestrictionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feature Restricted'),
        content: const Text(
            'This feature is not available in guest mode. Please sign in with a registered account to access all features.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Clear user data
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('name');
              await prefs.remove('email');
              await prefs.remove('uid');
              await prefs.remove('photoURL');
              await prefs.remove('isGuestMode');

              if (context.mounted) {
                // Navigate to login screen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  // Check and handle restricted feature access
  static Future<bool> checkAccess(BuildContext context, String featureKey) async {
    final isRestricted = await isFeatureRestricted(featureKey);

    if (isRestricted && context.mounted) {
      showRestrictionDialog(context);
      return false;
    }

    return true;
  }

  // Get available features based on mode
  static Future<List<String>> getAvailableFeatures() async {
    final prefs = await SharedPreferences.getInstance();
    final isGuestMode = prefs.getBool('isGuestMode') ?? false;

    final allFeatures = [
      'dashboard_view',
      'workout_view',
      'workout_save',
      'nutrition_view',
      'nutrition_tracking',
      'profile_view',
      'profile_edit',
      'progress_tracking',
      'account_settings',
      'theme_toggle',
    ];

    if (!isGuestMode) {
      return allFeatures; // All features available for registered users
    }

    // Return only unrestricted features for guest users
    return allFeatures.where((feature) => !const [
      'profile_edit',
      'workout_save',
      'nutrition_tracking',
      'progress_tracking',
      'account_settings',
    ].contains(feature)).toList();
  }
}
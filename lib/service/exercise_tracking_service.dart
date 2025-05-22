// Fix for exercise_tracking_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_service.dart';

class ExerciseTrackingService {
  // Singleton implementation
  static final ExerciseTrackingService _instance = ExerciseTrackingService._internal();
  factory ExerciseTrackingService() => _instance;
  ExerciseTrackingService._internal() {
    // Initialize the offline service when the tracking service is created
    _offlineService.initialize();
  }

  final OfflineService _offlineService = OfflineService();
  final String _localStorageKey = 'exercise_history';

  // Track a completed exercise
  Future<void> trackExercise({
    required String exerciseName,
    required String category,
    required int durationInSeconds,
  }) async {
    final exerciseData = {
      'name': exerciseName,
      'category': category,
      'durationInSeconds': durationInSeconds,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'synced': false,
    };

    // First save locally
    await _saveExerciseLocally(exerciseData);

    // Then try to sync with Firebase if online
    if (_offlineService.isOnline) {
      final success = await _offlineService.saveData('exercise', exerciseData);

      // If sync is successful, update status in local storage
      if (success) {
        exerciseData['synced'] = true;
        await _updateExerciseInLocalStorage(exerciseData);
      }
    }
  }

  Future<void> _updateExerciseInLocalStorage(Map<String, dynamic> updatedExercise) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_localStorageKey);

      if (historyJson != null) {
        final history = jsonDecode(historyJson) as List<dynamic>;

        // Find exercise index by timestamp
        final index = history.indexWhere((item) {
          final itemMap = Map<String, dynamic>.from(item);
          return itemMap['timestamp'] == updatedExercise['timestamp'];
        });

        if (index != -1) {
          // Update exercise in the list
          history[index] = updatedExercise;

          // Save updated list
          await prefs.setString(_localStorageKey, jsonEncode(history));
        }
      }
    } catch (e) {
      debugPrint('Error updating exercise in local storage: $e');
    }
  }

  // Save exercise data to local storage
  Future<void> _saveExerciseLocally(Map<String, dynamic> exerciseData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing exercise history or create new list
      final historyJson = prefs.getString(_localStorageKey);
      List<dynamic> history = [];

      if (historyJson != null) {
        history = jsonDecode(historyJson);
      }

      // Add new exercise data
      history.add(exerciseData);

      // Save updated history
      await prefs.setString(_localStorageKey, jsonEncode(history));
    } catch (e) {
      debugPrint('Error saving exercise locally: $e');
    }
  }

  // Get all exercise history from local storage
  Future<List<Map<String, dynamic>>> getExerciseHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_localStorageKey);

      if (historyJson != null) {
        final history = jsonDecode(historyJson) as List<dynamic>;
        return history.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      debugPrint('Error getting exercise history: $e');
    }

    return [];
  }

  // Get exercise history for a specific date
  Future<List<Map<String, dynamic>>> getExerciseHistoryForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final allHistory = await getExerciseHistory();

    return allHistory.where((exercise) {
      final timestamp = exercise['timestamp'] as int;
      final exerciseDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return exerciseDate.isAfter(startOfDay) && exerciseDate.isBefore(endOfDay);
    }).toList();
  }

  // Sync all local exercise data that hasn't been synced yet
  Future<bool> syncExerciseHistory() async {
    if (!_offlineService.isOnline) {
      debugPrint('Sync failed: Device is offline');
      return false;
    }

    try {
      final history = await getExerciseHistory();
      bool allSynced = true;
      bool anyChanges = false;

      for (final exerciseData in history) {
        // Skip already synced items
        if (exerciseData['synced'] == true) {
          continue;
        }

        // Create a copy of the exercise data to avoid modifying the original reference
        final exerciseDataCopy = Map<String, dynamic>.from(exerciseData);

        // Try to sync with Firebase
        final success = await _offlineService.saveData('exercise', exerciseDataCopy);

        if (success) {
          // Mark as synced in the copy
          exerciseDataCopy['synced'] = true;
          // Update in local storage
          await _updateExerciseInLocalStorage(exerciseDataCopy);
          anyChanges = true;
        } else {
          debugPrint('Failed to sync exercise: ${exerciseDataCopy['name']}');
          allSynced = false;
        }
      }

      // If any changes were made, reload the list from storage
      if (anyChanges) {
        // No need to update the shared preferences again as it's done in _updateExerciseInLocalStorage
        debugPrint('Sync completed with some changes');
      }

      return allSynced;
    } catch (e) {
      debugPrint('Error syncing exercise history: $e');
      return false;
    }
  }

  // Clear all exercise history
  Future<void> clearExerciseHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localStorageKey);
    } catch (e) {
      debugPrint('Error clearing exercise history: $e');
    }
  }
}
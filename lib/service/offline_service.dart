// Fix for offline_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class OfflineService {
  // Singleton implementation
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  // Properties
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _connectivitySubscription;
  bool _isOnline = true;
  final _syncController = StreamController<bool>.broadcast();
  final _pendingSyncItems = <String, Map<String, dynamic>>{};
  final _uuid = Uuid();
  bool _isInitialized = false;

  // Firebase instance
  final _database = FirebaseDatabase.instance.ref('users'); // Get a reference to the '/users' node

  // Stream to listen for sync events
  Stream<bool> get syncStream => _syncController.stream;

  // Initialize the service
  Future<void> initialize() async {
    // Prevent multiple initializations
    if (_isInitialized) return;
    _isInitialized = true;

    debugPrint('Initializing OfflineService');

    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    debugPrint('Initial connectivity status: ${_isOnline ? "Online" : "Offline"}');

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;

      debugPrint('Connectivity changed: ${_isOnline ? "Online" : "Offline"}');

      // If we are back online and were offline, sync data
      if (_isOnline && wasOffline) {
        debugPrint('Back online, attempting to sync data');
        syncPendingData();
      }

      // Notify listeners about connectivity status
      _syncController.add(_isOnline);
    });

    // Load any pending sync items from shared preferences
    await _loadPendingSyncItems();
  }

  // Getter for online status
  bool get isOnline => _isOnline;

  // Getter for pending sync count
  int get pendingSyncCount => _pendingSyncItems.length;

  // Save data to Firebase if online, otherwise store locally
  Future<bool> saveData(String dataType, Map<String, dynamic> data) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_isOnline) {
        // If online, save directly to Firebase
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final path = '${user.uid}/$dataType/${data['timestamp']}';
          await _database.child(path).set(data);
          debugPrint('Successfully saved data to Firebase: $path');
          return true;
        } else {
          debugPrint('Cannot save to Firebase: User not authenticated');
          return false;
        }
      } else {
        // If offline, save to pending items
        final itemId = _uuid.v4();
        final pendingItem = {
          'dataType': dataType,
          'data': data,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        };

        _pendingSyncItems[itemId] = pendingItem;
        await _savePendingSyncItems();
        debugPrint('Saved item to pending sync: $itemId');
        return true;
      }
    } catch (e) {
      debugPrint('Error saving data: $e');
      return false;
    }
  }

  // Check if user is authenticated with Firebase
  bool isUserAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }

  // Load pending sync items from SharedPreferences
  Future<void> _loadPendingSyncItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingItemsJson = prefs.getString('pending_sync_items');

      if (pendingItemsJson != null) {
        final decoded = jsonDecode(pendingItemsJson) as Map<String, dynamic>;
        _pendingSyncItems.clear();

        decoded.forEach((key, value) {
          _pendingSyncItems[key] = Map<String, dynamic>.from(value);
        });

        debugPrint('Loaded ${_pendingSyncItems.length} pending sync items');
      } else {
        debugPrint('No pending sync items found');
      }
    } catch (e) {
      debugPrint('Error loading pending sync items: $e');
    }
  }

  // Save pending sync items to SharedPreferences
  Future<void> _savePendingSyncItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_sync_items', jsonEncode(_pendingSyncItems));
      debugPrint('Saved ${_pendingSyncItems.length} pending sync items');
    } catch (e) {
      debugPrint('Error saving pending sync items: $e');
    }
  }

  // Sync all pending data with Firebase
  Future<bool> syncPendingData() async {
    if (!_isOnline) {
      debugPrint('Cannot sync: Device is offline');
      return false;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('Cannot sync: User not authenticated');
      return false;
    }

    if (_pendingSyncItems.isEmpty) {
      debugPrint('No pending items to sync');
      return true; // Nothing to sync is a success
    }

    bool allSynced = true;
    final itemsToRemove = <String>[];

    debugPrint('Starting sync of ${_pendingSyncItems.length} items');

    // Process each pending item
    for (final entry in _pendingSyncItems.entries) {
      final itemId = entry.key;
      final item = entry.value;

      try {
        final dataType = item['dataType'];
        final data = Map<String, dynamic>.from(item['data']);

        // Create path using timestamp as key
        final path = '${user.uid}/$dataType/${data['timestamp']}';
        await _database.child(path).set(data);
        debugPrint('Synced item $itemId to path: $path');

        // Mark item for removal after successful sync
        itemsToRemove.add(itemId);
      } catch (e) {
        debugPrint('Error syncing item $itemId: $e');
        allSynced = false;
      }
    }

    // Remove successfully synced items
    for (final itemId in itemsToRemove) {
      _pendingSyncItems.remove(itemId);
    }

    // Update stored pending items
    await _savePendingSyncItems();

    // Notify listeners about sync completion
    _syncController.add(true);

    debugPrint('Sync completed, removed ${itemsToRemove.length} items, ${_pendingSyncItems.length} items remain pending');

    return allSynced;
  }

  // Clean up resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncController.close();
    _isInitialized = false;
  }
}
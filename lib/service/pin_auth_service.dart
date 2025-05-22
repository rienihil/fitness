import 'dart:convert';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinAuthService {
  // Singleton implementation
  static final PinAuthService _instance = PinAuthService._internal();
  factory PinAuthService() => _instance;
  PinAuthService._internal();

  // Security constants
  static const int _pinLength = 6;
  static const int _maxPinAttempts = 5;
  static const _secureStorage = FlutterSecureStorage();

  // Store pin attempt count
  int _pinAttempts = 0;

  // PIN operations
  Future<bool> setupPin(String pin) async {
    if (pin.length != _pinLength || !RegExp(r'^\d+$').hasMatch(pin)) {
      return false;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }

      // Hash the PIN before storing
      final hashedPin = _hashPin(pin, user.uid);

      // Store the hashed PIN in secure storage
      await _secureStorage.write(key: 'user_pin_hash', value: hashedPin);

      // Store a flag in regular preferences to indicate PIN is set up
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pin_setup_complete', true);

      // Reset pin attempts
      _pinAttempts = 0;

      return true;
    } catch (e) {
      debugPrint('Error setting up PIN: $e');
      return false;
    }
  }

  Future<bool> verifyPin(String pin) async {
    try {
      // Check if we've exceeded max attempts
      if (_pinAttempts >= _maxPinAttempts) {
        return false;
      }

      // Get the stored pin hash
      final storedPinHash = await _secureStorage.read(key: 'user_pin_hash');
      if (storedPinHash == null) {
        return false;
      }

      // Get the user ID from SharedPreferences (stored during last login)
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('uid');
      if (uid == null) {
        return false;
      }

      // Verify the PIN
      final inputPinHash = _hashPin(pin, uid);
      final isCorrect = storedPinHash == inputPinHash;

      if (isCorrect) {
        // Reset attempts on successful verification
        _pinAttempts = 0;
      } else {
        // Increment attempts on failed verification
        _pinAttempts++;
      }

      return isCorrect;
    } catch (e) {
      debugPrint('Error verifying PIN: $e');
      return false;
    }
  }

  Future<bool> changePin(String oldPin, String newPin) async {
    // Verify old PIN first
    final isOldPinCorrect = await verifyPin(oldPin);
    if (!isOldPinCorrect) {
      return false;
    }

    // Then set up new PIN
    return setupPin(newPin);
  }

  Future<bool> isPinSetup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('pin_setup_complete') ?? false;
    } catch (e) {
      debugPrint('Error checking PIN setup: $e');
      return false;
    }
  }

  Future<void> resetPin() async {
    try {
      await _secureStorage.delete(key: 'user_pin_hash');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pin_setup_complete', false);

      _pinAttempts = 0;
    } catch (e) {
      debugPrint('Error resetting PIN: $e');
    }
  }

  // Check if the user is locked out
  bool get isPinLocked => _pinAttempts >= _maxPinAttempts;

  // Reset pin attempts
  void resetPinAttempts() {
    _pinAttempts = 0;
  }

  // Remaining attempts
  int get remainingAttempts => _maxPinAttempts - _pinAttempts;

  // Hash the PIN with the user's UID as salt
  String _hashPin(String pin, String uid) {
    final salt = uid.substring(0, Math.min(uid.length, 8));
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
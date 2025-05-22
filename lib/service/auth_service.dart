import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/pin_auth_service.dart';
import '../service/offline_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final PinAuthService _pinAuth = PinAuthService();
  final OfflineService _offlineService = OfflineService();

  // Auth change stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if we're online
  Future<bool> get isOnline async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Check connectivity
      if (!await isOnline) {
        throw FirebaseAuthException(
          code: 'network-error',
          message: 'No internet connection. Try offline login.',
        );
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user data to shared preferences
      await _saveUserData(credential.user);

      // Ensure guest mode is turned off
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGuestMode', false);

      return credential;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  // Create user with email and password
  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password, String name) async {
    try {
      // Check connectivity
      if (!await isOnline) {
        throw FirebaseAuthException(
          code: 'network-error',
          message: 'No internet connection. Account creation requires internet.',
        );
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      // Save user data to shared preferences
      await _saveUserData(credential.user);

      // Ensure guest mode is turned off
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGuestMode', false);

      return credential;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Check connectivity
      if (!await isOnline) {
        throw FirebaseAuthException(
          code: 'network-error',
          message: 'No internet connection. Google Sign-In requires internet.',
        );
      }

      // Trigger authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Save user data to shared preferences
      await _saveUserData(userCredential.user);

      // Ensure guest mode is turned off
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGuestMode', false);

      return userCredential;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      rethrow;
    }
  }

  // NEW: Sign in with PIN when offline
  Future<bool> signInWithPin(String pin) async {
    try {
      // Verify the PIN
      final isPinValid = await _pinAuth.verifyPin(pin);
      if (!isPinValid) {
        return false;
      }

      // PIN is valid, user is authenticated offline
      // We don't have a Firebase credential in this case,
      // but the app considers the user authenticated

      // Set an offline authentication flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('offline_authenticated', true);

      return true;
    } catch (e) {
      debugPrint('PIN sign in error: $e');
      return false;
    }
  }

  // NEW: Setup PIN for offline login
  Future<bool> setupPin(String pin) {
    return _pinAuth.setupPin(pin);
  }

  // NEW: Check if PIN is set up
  Future<bool> isPinSetup() {
    return _pinAuth.isPinSetup();
  }

  // Sign in as guest
  Future<void> signInAsGuest() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Set guest flag
      await prefs.setBool('isGuestMode', true);

      // Save minimal user data
      await prefs.setString('name', 'Guest User');
      await prefs.setString('email', 'guest@example.com');
      await prefs.setString('uid', 'guest-user-id');

      debugPrint('Signed in as guest');
    } catch (e) {
      debugPrint('Guest sign in error: $e');
      rethrow;
    }
  }

  // Check if user is in guest mode
  Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isGuestMode') ?? false;
  }

  // Check if user is authenticated (either online or offline)
  Future<bool> isAuthenticated() async {
    if (_auth.currentUser != null) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('offline_authenticated') ?? false;
  }

  // Save user data to shared preferences
  Future<void> _saveUserData(User? user) async {
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', user.displayName ?? 'User');
    await prefs.setString('email', user.email ?? 'No email');
    await prefs.setString('uid', user.uid);
    await prefs.setBool('offline_authenticated', true);

    // Save profile picture URL if available
    if (user.photoURL != null) {
      await prefs.setString('photoURL', user.photoURL!);
    }

    // Sync any pending offline data now that we're logged in
    _offlineService.syncPendingData();
  }

  // Sign out - handles both online and offline authentication
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();

      // Clear auth-related preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('offline_authenticated');
      await prefs.remove('name');
      await prefs.remove('email');
      await prefs.remove('uid');
      await prefs.remove('photoURL');
      await prefs.remove('isGuestMode');

      // Note: We do NOT clear the PIN setup - that stays for future offline logins
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      // Check connectivity
      if (!await isOnline) {
        throw FirebaseAuthException(
          code: 'network-error',
          message: 'No internet connection. Password reset requires internet.',
        );
      }

      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Password reset error: $e');
      rethrow;
    }
  }
  // Метод для удаления аккаунта пользователя
  Future<void> deleteAccount(String password) async {
    try {
      // Проверяем подключение к интернету
      if (!await isOnline) {
        throw FirebaseAuthException(
          code: 'network-error',
          message: 'No internet connection. Account deletion requires internet.',
        );
      }

      // Проверяем, что пользователь авторизован
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'No authenticated user found.',
        );
      }

      // Для повторной аутентификации перед удалением аккаунта
      if (user.email != null && password.isNotEmpty) {
        // Создаем учетные данные для повторной аутентификации
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );

        // Повторно аутентифицируем пользователя
        await user.reauthenticateWithCredential(credential);
      }

      // Удаляем учетную запись пользователя в Firebase
      await user.delete();

      // Очищаем локальные данные
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Очищаем все хранилище предпочтений

      // Также очищаем PIN и любые другие данные аутентификации
      await _pinAuth.resetPin();

      debugPrint('Account successfully deleted');
    } catch (e) {
      debugPrint('Account deletion error: $e');
      rethrow;
    }
  }

  // Force sync pending data
  Future<bool> syncPendingData() {
    return _offlineService.syncPendingData();
  }

  // Get pending sync count
  int get pendingSyncCount => _offlineService.pendingSyncCount;

  // НОВЫЕ МЕТОДЫ ДЛЯ ОБНОВЛЕНИЯ ПРОФИЛЯ

  // Обновление имени пользователя
  Future<void> updateUserName(String newName) async {
    try {
      // Проверяем подключение к интернету
      if (!await isOnline) {
        throw FirebaseAuthException(
          code: 'network-error',
          message: 'No internet connection. Profile update requires internet.',
        );
      }

      // Проверяем, что пользователь авторизован
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'No authenticated user found.',
        );
      }

      // Обновляем имя в Firebase
      await user.updateDisplayName(newName);

      // Обновляем имя в локальном хранилище
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', newName);

    } catch (e) {
      debugPrint('Update name error: $e');
      rethrow;
    }
  }

  // Повторная аутентификация пользователя (требуется для некоторых операций)
  Future<void> reauthenticateUser(String email, String password) async {
    try {
      // Проверяем подключение к интернету
      if (!await isOnline) {
        throw FirebaseAuthException(
          code: 'network-error',
          message: 'No internet connection. Reauthentication requires internet.',
        );
      }

      // Проверяем, что пользователь авторизован
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'No authenticated user found.',
        );
      }

      // Создаем учетные данные для повторной аутентификации
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      // Повторно аутентифицируем пользователя
      await user.reauthenticateWithCredential(credential);

    } catch (e) {
      debugPrint('Reauthentication error: $e');
      rethrow;
    }
  }

  // Обновление пароля пользователя
  Future<void> updateUserPassword(String newPassword) async {
    try {
      // Проверяем подключение к интернету
      if (!await isOnline) {
        throw FirebaseAuthException(
          code: 'network-error',
          message: 'No internet connection. Password update requires internet.',
        );
      }

      // Проверяем, что пользователь авторизован
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'No authenticated user found.',
        );
      }

      // Обновляем пароль в Firebase
      await user.updatePassword(newPassword);

    } catch (e) {
      debugPrint('Update password error: $e');
      rethrow;
    }
  }
}
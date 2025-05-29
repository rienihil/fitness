import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

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

      // Save user data to shared preferences and Realtime Database
      await _saveUserData(credential.user);
      await _syncUserToDatabase(credential.user);

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

      // КРИТИЧНО: Обновляем displayName сразу после создания аккаунта
      if (credential.user != null) {
        debugPrint('🔧 Setting displayName during account creation: $name');
        await _updateDisplayNameRobust(credential.user!, name);

        // Дополнительная проверка и попытка обновления
        await credential.user!.reload();
        final updatedUser = _auth.currentUser;

        if (updatedUser?.displayName != name) {
          debugPrint('⚠️ DisplayName not set properly, trying again...');
          await _updateDisplayNameRobust(updatedUser!, name);
        }

        debugPrint('✅ Final displayName after account creation: ${_auth.currentUser?.displayName}');

        // Create user profile in Realtime Database
        await _createUserProfile(updatedUser!, name);
      }

      // Save user data to shared preferences
      await _saveUserData(_auth.currentUser);

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

      // For Google sign-in, the displayName should already be set
      // But let's verify and fix if needed
      if (userCredential.user != null) {
        final currentDisplayName = userCredential.user!.displayName;
        debugPrint('Google sign-in displayName: $currentDisplayName');

        // If displayName is not set or is different from Google profile name
        if (currentDisplayName == null || currentDisplayName.isEmpty) {
          final googleDisplayName = googleUser.displayName ?? 'Google User';
          debugPrint('⚠️ Fixing missing displayName from Google: $googleDisplayName');
          await _updateDisplayNameRobust(userCredential.user!, googleDisplayName);
        }

        // Sync user to Realtime Database
        await _syncUserToDatabase(userCredential.user);
      }

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

  // Sign in with PIN when offline
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

  // Setup PIN for offline login
  Future<bool> setupPin(String pin) {
    return _pinAuth.setupPin(pin);
  }

  // Check if PIN is set up
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

  // Create user profile in Realtime Database
  Future<void> _createUserProfile(User user, String displayName) async {
    try {
      final userRef = _database.child('users').child(user.uid);

      final userData = {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': displayName,
        'photoURL': user.photoURL ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'emailVerified': user.emailVerified,
        'createdAt': ServerValue.timestamp,
        'lastSignInAt': ServerValue.timestamp,
        'isOnline': true,
        'deviceInfo': {
          'platform': 'flutter',
          'version': '1.0.0',
        }
      };

      await userRef.set(userData);
      debugPrint('✅ User profile created in Realtime Database');
    } catch (e) {
      debugPrint('❌ Error creating user profile in database: $e');
    }
  }

  // Sync user to Realtime Database
  Future<void> _syncUserToDatabase(User? user) async {
    if (user == null) return;

    try {
      final userRef = _database.child('users').child(user.uid);

      // Check if user exists in database
      final snapshot = await userRef.get();

      final userData = {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? 'User',
        'photoURL': user.photoURL ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'emailVerified': user.emailVerified,
        'lastSignInAt': ServerValue.timestamp,
        'isOnline': true,
      };

      if (snapshot.exists) {
        // Update existing user
        await userRef.update(userData);
        debugPrint('✅ User data updated in Realtime Database');
      } else {
        // Create new user profile
        userData['createdAt'] = ServerValue.timestamp;
        await userRef.set(userData);
        debugPrint('✅ New user profile created in Realtime Database');
      }

      // Set user offline when app is closed
      userRef.child('isOnline').onDisconnect().set(false);

    } catch (e) {
      debugPrint('❌ Error syncing user to database: $e');
    }
  }

  // Update user name in Firebase Auth and Realtime Database
  Future<void> updateUserName(String newName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      debugPrint('🔄 Starting comprehensive name update to: "$newName"');

      // Step 1: Update displayName in Firebase Auth
      await _updateDisplayNameRobust(user, newName);

      // Step 2: Update in Realtime Database
      if (await isOnline) {
        final userRef = _database.child('users').child(user.uid);
        await userRef.update({
          'displayName': newName,
          'lastUpdatedAt': ServerValue.timestamp,
        });
        debugPrint('✅ Name updated in Realtime Database');
      }

      // Step 3: Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', newName);
      debugPrint('✅ Name updated in local storage');

      debugPrint('✅ Comprehensive name update completed');

    } catch (e) {
      debugPrint('❌ Error updating user name: $e');
      rethrow;
    }
  }

  // Update user password
  Future<void> updateUserPassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      await user.updatePassword(newPassword);

      // Update last password change timestamp in database
      if (await isOnline) {
        final userRef = _database.child('users').child(user.uid);
        await userRef.update({
          'lastPasswordChangeAt': ServerValue.timestamp,
        });
      }

      debugPrint('✅ Password updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating password: $e');
      rethrow;
    }
  }

  // Reauthenticate user
  Future<void> reauthenticateUser(String email, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      debugPrint('✅ User reauthenticated successfully');
    } catch (e) {
      debugPrint('❌ Reauthentication failed: $e');
      rethrow;
    }
  }

  // Get current user data from all sources
  Future<Map<String, dynamic>> getCurrentUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _auth.currentUser;

      Map<String, dynamic> userData = {
        'name': prefs.getString('name') ?? 'User',
        'email': prefs.getString('email') ?? 'No email',
        'uid': prefs.getString('uid') ?? 'No UID',
        'photoURL': prefs.getString('photoURL') ?? '',
        'isOnline': await isOnline,
        'isGuestMode': await isGuestMode(),
      };

      // Add Firebase Auth data if available
      if (user != null) {
        userData.addAll({
          'firebaseDisplayName': user.displayName ?? 'No display name',
          'firebaseEmail': user.email ?? 'No email',
          'firebaseUID': user.uid,
          'firebasePhotoURL': user.photoURL ?? '',
          'emailVerified': user.emailVerified,
        });

        // Get data from Realtime Database if online
        if (await isOnline) {
          try {
            final userRef = _database.child('users').child(user.uid);
            final snapshot = await userRef.get();

            if (snapshot.exists) {
              final dbData = Map<String, dynamic>.from(snapshot.value as Map);
              userData['databaseData'] = dbData;
            }
          } catch (e) {
            debugPrint('Error fetching database data: $e');
          }
        }
      }

      return userData;
    } catch (e) {
      debugPrint('Error getting current user data: $e');
      return {};
    }
  }

  // Get Firebase displayName specifically
  Future<String> getFirebaseDisplayName() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 'User offline';
      }

      await user.reload();
      final updatedUser = _auth.currentUser;
      return updatedUser?.displayName ?? 'No display name';
    } catch (e) {
      debugPrint('Error getting Firebase display name: $e');
      return 'Error: ${e.toString()}';
    }
  }

  // Force Firebase sync
  Future<void> forceFirebaseSync() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await user.reload();

      // Also sync with database if online
      if (await isOnline) {
        await _syncUserToDatabase(user);
      }

      debugPrint('🔄 Firebase sync completed');
    } catch (e) {
      debugPrint('❌ Firebase sync failed: $e');
    }
  }

  // Get user data from Realtime Database
  Future<Map<String, dynamic>?> getUserFromDatabase(String uid) async {
    try {
      if (!await isOnline) return null;

      final userRef = _database.child('users').child(uid);
      final snapshot = await userRef.get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user from database: $e');
      return null;
    }
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
      final user = _auth.currentUser;

      // Set user offline in database before signing out
      if (user != null && await isOnline) {
        try {
          final userRef = _database.child('users').child(user.uid);
          await userRef.update({
            'isOnline': false,
            'lastSeenAt': ServerValue.timestamp,
          });
        } catch (e) {
          debugPrint('Error updating user status on signout: $e');
        }
      }

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

      debugPrint('✅ User signed out successfully');

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

  // Delete user account
  Future<void> deleteAccount(String password) async {
    try {
      // Check connectivity
      if (!await isOnline) {
        throw FirebaseAuthException(
          code: 'network-error',
          message: 'No internet connection. Account deletion requires internet.',
        );
      }

      // Check if user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'No authenticated user found.',
        );
      }

      // Reauthenticate before deletion
      if (user.email != null && password.isNotEmpty) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }

      // Delete user data from Realtime Database
      try {
        final userRef = _database.child('users').child(user.uid);
        await userRef.remove();
        debugPrint('✅ User data deleted from Realtime Database');
      } catch (e) {
        debugPrint('❌ Error deleting user data from database: $e');
      }

      // Delete user account in Firebase
      await user.delete();

      // Clear local data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear PIN data
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

  // КРИТИЧНО УЛУЧШЕННЫЙ МЕТОД ДЛЯ ОБНОВЛЕНИЯ DISPLAYNAME
  Future<void> _updateDisplayNameRobust(User user, String newName) async {
    debugPrint('🔧 Starting robust displayName update to: "$newName"');

    if (newName.trim().isEmpty) {
      debugPrint('❌ Empty name provided, skipping update');
      return;
    }

    try {
      // Метод 1: Прямое обновление через updateProfile
      debugPrint('📝 Method 1: updateProfile');
      await user.updateProfile(displayName: newName);
      await user.reload();
      await Future.delayed(const Duration(milliseconds: 500));

      User? updatedUser = _auth.currentUser;
      debugPrint('Method 1 result: ${updatedUser?.displayName}');

      // Метод 2: Повторное обновление если первый не сработал
      if (updatedUser?.displayName != newName) {
        debugPrint('📝 Method 2: Retry updateProfile');
        await updatedUser?.updateProfile(displayName: newName);
        await updatedUser?.reload();
        await Future.delayed(const Duration(milliseconds: 500));
        updatedUser = _auth.currentUser;
        debugPrint('Method 2 result: ${updatedUser?.displayName}');
      }

      // Метод 3: Использование updateDisplayName напрямую
      if (updatedUser?.displayName != newName) {
        debugPrint('📝 Method 3: updateDisplayName');
        await updatedUser?.updateDisplayName(newName);
        await updatedUser?.reload();
        await Future.delayed(const Duration(milliseconds: 500));
        updatedUser = _auth.currentUser;
        debugPrint('Method 3 result: ${updatedUser?.displayName}');
      }

      // Финальная проверка
      final finalUser = _auth.currentUser;
      if (finalUser?.displayName == newName) {
        debugPrint('✅ DisplayName successfully updated to: "${finalUser?.displayName}"');
      } else {
        debugPrint('⚠️ DisplayName update may not have taken effect. Current: "${finalUser?.displayName}", Expected: "$newName"');
      }

    } catch (e) {
      debugPrint('❌ Error updating displayName: $e');
      rethrow;
    }
  }

  // Update user extension for displayName directly
  Future<void> updateDisplayName(String newName) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    await _updateDisplayNameRobust(user, newName);
  }

  // Set user online status
  Future<void> setUserOnlineStatus(bool isOnline) async {
    try {
      final user = _auth.currentUser;
      if (user == null || !await this.isOnline) return;

      final userRef = _database.child('users').child(user.uid);
      await userRef.update({
        'isOnline': isOnline,
        'lastSeenAt': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  // Get all users from database (for admin or other features)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      if (!await isOnline) return [];

      final usersRef = _database.child('users');
      final snapshot = await usersRef.get();

      if (snapshot.exists) {
        final usersData = Map<String, dynamic>.from(snapshot.value as Map);
        return usersData.values
            .map((user) => Map<String, dynamic>.from(user as Map))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  // Search users by name or email
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      if (!await isOnline || query.trim().isEmpty) return [];

      final usersRef = _database.child('users');
      final snapshot = await usersRef.get();

      if (snapshot.exists) {
        final usersData = Map<String, dynamic>.from(snapshot.value as Map);
        final queryLower = query.toLowerCase();

        return usersData.values
            .map((user) => Map<String, dynamic>.from(user as Map))
            .where((user) {
          final name = (user['displayName'] ?? '').toString().toLowerCase();
          final email = (user['email'] ?? '').toString().toLowerCase();
          return name.contains(queryLower) || email.contains(queryLower);
        })
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Update user profile picture
  Future<void> updateUserProfilePicture(String photoURL) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Update in Firebase Auth
      await user.updatePhotoURL(photoURL);
      await user.reload();

      // Update in Realtime Database
      if (await isOnline) {
        final userRef = _database.child('users').child(user.uid);
        await userRef.update({
          'photoURL': photoURL,
          'lastUpdatedAt': ServerValue.timestamp,
        });
      }

      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('photoURL', photoURL);

      debugPrint('✅ Profile picture updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating profile picture: $e');
      rethrow;
    }
  }

  // Listen to user changes in real-time
  Stream<Map<String, dynamic>?> getUserStream(String uid) {
    return _database
        .child('users')
        .child(uid)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    });
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      if (!await isOnline) return {};

      final usersRef = _database.child('users');
      final snapshot = await usersRef.get();

      if (snapshot.exists) {
        final usersData = Map<String, dynamic>.from(snapshot.value as Map);
        final users = usersData.values.map((user) => Map<String, dynamic>.from(user as Map)).toList();

        final totalUsers = users.length;
        final onlineUsers = users.where((user) => user['isOnline'] == true).length;
        final verifiedUsers = users.where((user) => user['emailVerified'] == true).length;

        return {
          'totalUsers': totalUsers,
          'onlineUsers': onlineUsers,
          'verifiedUsers': verifiedUsers,
          'offlineUsers': totalUsers - onlineUsers,
          'unverifiedUsers': totalUsers - verifiedUsers,
        };
      }
      return {};
    } catch (e) {
      debugPrint('Error getting user stats: $e');
      return {};
    }
  }
}
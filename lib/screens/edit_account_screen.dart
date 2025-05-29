import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/auth_service.dart';

class EditAccountScreen extends StatefulWidget {
  final String currentName;
  final String currentEmail;

  const EditAccountScreen({
    Key? key,
    required this.currentName,
    required this.currentEmail,
  }) : super(key: key);

  @override
  _EditAccountScreenState createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String _errorMessage = '';
  String _successMessage = '';
  String _firebaseStatus = '';

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
    _checkInitialFirebaseStatus();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Check initial Firebase status
  Future<void> _checkInitialFirebaseStatus() async {
    final firebaseDisplayName = await _authService.getFirebaseDisplayName();
    setState(() {
      _firebaseStatus = 'Firebase display name: $firebaseDisplayName';
    });
  }

  // Update user profile name
  Future<void> _updateName() async {
    final newName = _nameController.text.trim();
    if (newName == widget.currentName) {
      return; // No change, no need to update
    }

    if (newName.isEmpty) {
      setState(() {
        _errorMessage = 'Name cannot be empty';
        _successMessage = '';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('🔄 Starting name update process...');

      // Update name in Firebase (this will also update local storage)
      await _authService.updateUserName(newName);

      // Multiple sync attempts to ensure data is updated
      debugPrint('🔄 Performing sync attempts...');

      for (int attempt = 1; attempt <= 3; attempt++) {
        await _authService.forceFirebaseSync();
        await Future.delayed(Duration(milliseconds: 300 * attempt));

        final firebaseDisplayName = await _authService.getFirebaseDisplayName();
        debugPrint('Sync attempt $attempt: $firebaseDisplayName');

        if (firebaseDisplayName == newName) {
          debugPrint('✅ Name sync successful on attempt $attempt');
          break;
        }
      }

      // Get final data from Firebase to verify update
      final userData = await _authService.getCurrentUserData();
      final actualName = userData['name'] ?? newName;
      final firebaseDisplayName = await _authService.getFirebaseDisplayName();

      setState(() {
        _successMessage = 'Name updated successfully!\nDisplayName in Firebase: $firebaseDisplayName';
        _errorMessage = '';
        _firebaseStatus = 'Firebase display name: $firebaseDisplayName';
      });

      // Update field with actual value from Firebase
      _nameController.text = actualName;

      debugPrint('✅ Name update completed successfully');

    } catch (e) {
      debugPrint('❌ Name update failed: $e');
      setState(() {
        _errorMessage = 'Failed to update name: ${e.toString()}';
        _successMessage = '';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Update user password
  Future<void> _updatePassword() async {
    if (_newPasswordController.text.isEmpty) {
      return; // No password change requested
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'New passwords do not match');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Reauthenticate user with current password
      await _authService.reauthenticateUser(widget.currentEmail, _currentPasswordController.text);

      // Update password in Firebase
      await _authService.updateUserPassword(_newPasswordController.text);

      // Clear password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      setState(() {
        _successMessage = 'Password updated successfully';
        _errorMessage = '';
      });
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'wrong-password':
          message = 'Current password is incorrect';
          break;
        case 'weak-password':
          message = 'New password is too weak';
          break;
        case 'requires-recent-login':
          message = 'This operation requires recent authentication. Please log in again before retrying';
          break;
        case 'network-error':
          message = 'No internet connection. Profile update requires internet.';
          break;
        default:
          message = 'Error updating password: ${e.message ?? e.code}';
      }
      setState(() {
        _errorMessage = message;
        _successMessage = '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update password: ${e.toString()}';
        _successMessage = '';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Save all changes
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    // Clear previous messages
    setState(() {
      _errorMessage = '';
      _successMessage = '';
    });

    // Update profile information
    await _updateName();

    // If password field is filled, update password too
    if (_currentPasswordController.text.isNotEmpty &&
        _newPasswordController.text.isNotEmpty) {
      await _updatePassword();
    }

    // If no errors, navigate back with updated name
    if (_errorMessage.isEmpty) {
      try {
        // Additional sync before getting final data
        await _authService.forceFirebaseSync();
        await Future.delayed(const Duration(milliseconds: 500));

        final userData = await _authService.getCurrentUserData();
        final updatedName = userData['name'] ?? _nameController.text;
        final firebaseDisplayName = await _authService.getFirebaseDisplayName();

        debugPrint('Final check before navigation:');
        debugPrint('- userData name: $updatedName');
        debugPrint('- Firebase displayName: $firebaseDisplayName');

        if (_successMessage.isNotEmpty) {
          // Show success message briefly then navigate back
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) Navigator.pop(context, updatedName);
          });
        } else {
          // Navigate back immediately if only name was updated
          if (mounted) Navigator.pop(context, updatedName);
        }
      } catch (e) {
        debugPrint('Error getting final user data: $e');
        // Fallback to controller text if Firebase data fetch fails
        if (mounted) Navigator.pop(context, _nameController.text);
      }
    }
  }

  // Enhanced Firebase sync check
  Future<void> _checkFirebaseSync() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('🔄 Manual sync check initiated...');

      // Force sync multiple times
      for (int i = 1; i <= 3; i++) {
        await _authService.forceFirebaseSync();
        await Future.delayed(Duration(milliseconds: 200 * i));
      }

      final userData = await _authService.getCurrentUserData();
      final firebaseDisplayName = await _authService.getFirebaseDisplayName();
      final localName = userData['name'];

      setState(() {
        _successMessage = '''Sync Results:
• Firebase displayName: "$firebaseDisplayName"
• Local storage name: "$localName"
• Controller text: "${_nameController.text}"
${firebaseDisplayName == _nameController.text ? "✅ Sync successful!" : "⚠️ Sync may be pending..."}''';
        _errorMessage = '';
        _firebaseStatus = 'Firebase display name: $firebaseDisplayName';
      });

      // Auto-update field if Firebase has different data
      if (firebaseDisplayName != 'User offline' &&
          firebaseDisplayName != 'No display name' &&
          !firebaseDisplayName.startsWith('Error:') &&
          firebaseDisplayName != _nameController.text) {
        _nameController.text = firebaseDisplayName;
      }

      debugPrint('✅ Manual sync check completed');

    } catch (e) {
      setState(() {
        _errorMessage = 'Sync check failed: $e';
        _successMessage = '';
      });
      debugPrint('❌ Manual sync check failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Force update Firebase displayName (debugging tool)
  Future<void> _forceUpdateDisplayName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('🔧 Force updating Firebase displayName...');

      // Direct Firebase update without additional logic
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(newName);
        await user.reload();

        // Wait for sync
        await Future.delayed(const Duration(milliseconds: 1000));

        final updatedUser = FirebaseAuth.instance.currentUser;
        final finalDisplayName = updatedUser?.displayName ?? 'Failed to update';

        setState(() {
          _successMessage = 'Force update completed!\nFirebase displayName: $finalDisplayName';
          _errorMessage = '';
          _firebaseStatus = 'Firebase display name: $finalDisplayName';
        });

        debugPrint('✅ Force update completed: $finalDisplayName');
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      debugPrint('❌ Force update failed: $e');
      setState(() {
        _errorMessage = 'Force update failed: $e';
        _successMessage = '';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Account'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Debug sync button
          IconButton(
            onPressed: _isLoading ? null : _checkFirebaseSync,
            icon: const Icon(Icons.sync),
            tooltip: 'Check Firebase Sync',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Firebase Status Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Firebase Status',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _firebaseStatus,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _forceUpdateDisplayName,
                        icon: const Icon(Icons.build, size: 16),
                        label: const Text('Force Update'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email Field (read-only)
              TextFormField(
                initialValue: widget.currentEmail,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                enabled: false,
              ),

              const SizedBox(height: 24),

              // Password Change Section
              const Text(
                'Change Password (Optional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Current Password
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                obscureText: !_isPasswordVisible,
              ),

              const SizedBox(height: 16),

              // New Password
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isNewPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
                  ),
                ),
                obscureText: !_isNewPasswordVisible,
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Confirm New Password
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                  ),
                ),
                obscureText: !_isConfirmPasswordVisible,
                validator: (value) {
                  if (_newPasswordController.text.isNotEmpty && value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),

              // Success Message
              if (_successMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _successMessage,
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ),

              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Saving Changes...'),
                  ],
                )
                    : const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel Button
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}